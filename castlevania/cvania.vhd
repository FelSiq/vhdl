LIBRARY ieee;
USE ieee.std_logic_1164.all;
--use ieee.numeric_std.all;
USE ieee.std_logic_arith.all;
-- CLOCK DE 1MG HZ
ENTITY cvania IS
	PORT(
		-- SINAIS DE OUTPUT NA TELA
		key_in: IN std_logic_vector(7 downto 0);
		vga_pos: OUT std_logic_vector(15 downto 0);
		vga_char: OUT std_logic_vector(15 downto 0);
		vga_write: OUT std_logic;
		
		-- SINAIS DE CARACTERISTICAS
		fase	: OUT	STD_LOGIC_VECTOR(7 DOWNTO 0);
		
		-- SINAIS DE CONTROLE
		clk	:	IN STD_LOGIC;
		reset	:	IN STD_LOGIC
	);
end cvania;

ARCHITECTURE THE_GAME OF cvania IS
	-- ####################################
	-- #DECLARACAO DOS COMPONENTES DO JOGO#
	-- ####################################
	
	--####################################################################
	-- 1. PLAYER
	COMPONENT personagem IS
		PORT(
		-- STATE SIGNALS
			state_mov		: OUT STD_LOGIC_VECTOR(7 downto 0);
			state_control	: OUT STD_LOGIC_VECTOR(7 downto 0);
			state_action	: OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
			
			-- CHARACTERISTICS SIGNALS
			x					: OUT UNSIGNED(7 DOWNTO 0);
			y					: OUT UNSIGNED(7 DOWNTO 0);
			dead				: OUT STD_LOGIC;
			isAtacked		: IN STD_LOGIC;
			isAtacking		: IN STD_LOGIC;
			delayattack		: OUT UNSIGNED(7 DOWNTO 0);
			sig_energia		: OUT UNSIGNED(7 DOWNTO 0);
			
			-- MOVEMENT SIGNALS
			moveSignal		: IN STD_LOGIC_VECTOR(1 DOWNTO 0);
			moveResponse	: OUT STD_LOGIC;
			moveDirection	: OUT STD_LOGIC; -- '1' LEFT/ '0' RIGHT
			-- MOVE SIGNAL: 
			--		00 = NO MOVEMENT, 
			--		01 = TO THE LEFT, 
			--		10 = TO THE RIGHT, 
			--		11 = NO MOVEMENT
			
			-- JUMP SIGNALS
			jumpSignal		: IN STD_LOGIC;
			jumpResponse	: OUT STD_LOGIC;
			
			-- CONTROL SIGNALS
			clk				: IN STD_LOGIC;
			reset				: IN STD_LOGIC;
			signal_enable_global : IN STD_LOGIC;
			signal_force_reset : IN STD_LOGIC
		);
	END COMPONENT;
	--####################################################################
	-- 2. OPONENTES
	-- ENEMY1 É UM INIMIGO COMUM, USADO PARA TUTORIAL & FILLING PURPOSES
	COMPONENT enemy1 IS
	PORT(
		-- SINAIS DE MAQUINAS DE ESTADO
		state_mov		: OUT STD_LOGIC_VECTOR(7 downto 0);
		state_control	: OUT STD_LOGIC_VECTOR(7 downto 0);
		-- CHARACTERISTICS SIGNALS
		x					: OUT UNSIGNED(7 DOWNTO 0);
		y					: OUT UNSIGNED(7 DOWNTO 0);
		dead				: OUT STD_LOGIC;
		isAtacked		: IN STD_LOGIC;
		direction		: OUT STD_LOGIC;
		-- SINAIS DE INICIALIZACAO
		energia_start	: IN UNSIGNED(3 DOWNTO 0);
		x_start			: IN UNSIGNED(7 DOWNTO 0);
		y_start			: IN UNSIGNED(7 DOWNTO 0);
		-- CONTROL SIGNALS
		clk				: IN STD_LOGIC;
		reset				: IN STD_LOGIC;
		signal_enable_global : IN STD_LOGIC;
		signal_force_reset	: in STD_LOGIC
	);
	END COMPONENT;
	-- ENEMY2 ANDARÁ MAIS RÁPIDO E TERÁ MAIS ENERGIA QUE O ENEMY1 E SERÁ MAIS INTELIGENTE,
	-- AVANÇANDO EM DIREÇÃO AO JOGADOR
	--####################################################################
	-- OBJETOS EM GERAL
	COMPONENT torchs IS
		PORT(
			--	SINAIS DE ESTADO
			state		: OUT STD_LOGIC_VECTOR(7 downto 0);
			-- SINAIS DE CARACTERISTICA
			broken	: OUT STD_LOGIC;
			atacked	: IN STD_LOGIC;
			x			: IN UNSIGNED(7 DOWNTO 0);
			y			: IN UNSIGNED(7 DOWNTO 0);
			-- SINAIS DE CONTROLE
			clk		:	IN STD_LOGIC;
			reset		:	IN STD_LOGIC;
			signal_enable_global : IN STD_LOGIC
		);
	END COMPONENT;
	--####################################################################
	-- SINAIS EXTERNOS DESTE MÓDULO
	SIGNAL signal_enable_global				: STD_LOGIC := '0';
	SIGNAL signal_fase							: STD_LOGIC_VECTOR(7 DOWNTO 0) := x"00";
	SIGNAL signal_endgame						: STD_LOGIC := '0';
	SIGNAL signal_win 							: STD_LOGIC := '0';
	SIGNAL signal_force_reset					: STD_LOGIC := '0';
	-- QUANDO TODOS OS INIMIGOS ESTIVEREM MORTOS, E AVANCADO A FASE
	-- O JOGO TERA 5 FASES DIFERENTES, E SERA BASEADO EM WAVE DE INIMIGOS.
	-- A DIFERENÇA SERA NA FREQUENCIA DOS INIMIGOS E NO TIPO DOS INIMIGOS
	-- #####################################################################
	-- SINAIS EXTERNOS PARA O JOGADOR
	SIGNAL signal_jogador_stateMov			: STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL signal_jogador_stateControl		: STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL signal_jogador_stateAction		: STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL signal_jogador_x						: UNSIGNED(7 DOWNTO 0);
	SIGNAL signal_jogador_y						: UNSIGNED(7 DOWNTO 0);
	SIGNAL signal_jogador_dead					: STD_LOGIC;
	SIGNAL signal_jogador_isAtacked			: STD_LOGIC := '0';
	SIGNAL signal_jogador_isAtacking			: STD_LOGIC;
	SIGNAL signal_jogador_delayattacking	: UNSIGNED(7 DOWNTO 0);
	SIGNAL signal_jogador_energia				: UNSIGNED(7 DOWNTO 0) := x"0F";
	SIGNAL signal_jogador_moveSignal			: STD_LOGIC_VECTOR(1 DOWNTO 0) := "11";
	-- IMPORTANT TO RENEMBER!!
		--		00 = NO MOVEMENT, 
		--		01 = TO THE LEFT, 
		--		10 = TO THE RIGHT, 
		--		11 = NO MOVEMENT
	SIGNAL signal_jogador_moveResponse		: STD_LOGIC;
	SIGNAL signal_jogador_moveDirection		: STD_LOGIC; -- '1' LEFT/ '0' RIGHT
	SIGNAL signal_jogador_jumpSignal			: STD_LOGIC;
	SIGNAL signal_jogador_jumpResponse		: STD_LOGIC;
	-- #####################################################################
	-- SINAIS EXTERNOS PARA OS INIMIGOS
	
	-- #####################################################################
	TYPE ENEMY_VEC IS ARRAY(0 TO 4) OF STD_LOGIC_VECTOR(7 DOWNTO 0);
	TYPE ENEMY_SIG7 IS ARRAY(0 TO 4) OF UNSIGNED (7 DOWNTO 0);
	TYPE ENEMY_SIG3 IS ARRAY(0 TO 4) OF UNSIGNED (3 DOWNTO 0);
	TYPE ENEMY_STDLOGIC IS ARRAY(0 TO 4) OF STD_LOGIC;
	-- #####################################################################
	SIGNAL signal_enemy_stateMov				: ENEMY_VEC;
	SIGNAL signal_enemy_stateControl			: ENEMY_VEC;
	SIGNAL signal_enemy_x						: ENEMY_SIG7;
	SIGNAL signal_enemy_y						: ENEMY_SIG7;
	SIGNAL signal_enemy_dead					: ENEMY_STDLOGIC;
	SIGNAL signal_enemy_isAtacked				: ENEMY_STDLOGIC;
	SIGNAL signal_enemy_direction				: ENEMY_STDLOGIC;
	SIGNAL signal_enemy_energiaStart			: ENEMY_SIG3;
	SIGNAL signal_enemy_xStart					: ENEMY_SIG7;
	SIGNAL signal_enemy_yStart					: ENEMY_SIG7;
	-- #####################################################################
	TYPE TORCH_VEC IS ARRAY(0 TO 2) OF STD_LOGIC_VECTOR(7 DOWNTO 0);
	TYPE TORCH_SIG5 IS ARRAY(0 TO 2) OF UNSIGNED(7 DOWNTO 0);
	TYPE TORCH_STDLOGIC IS ARRAY(0 TO 2) OF STD_LOGIC;
	-- #####################################################################
	-- SINAIS EXTERNOS PARA OS OBJETOS
	SIGNAL signal_torchs_state					: TORCH_VEC;
	SIGNAL signal_torchs_broken				: TORCH_STDLOGIC;
	SIGNAL signal_torchs_atacked				: TORCH_STDLOGIC;
	SIGNAL signal_torchs_x						: TORCH_SIG5;
	SIGNAL signal_torchs_y						: TORCH_SIG5;
	-- #####################################################################
	-- INÍCIO DA ARCHITECTURE
	BEGIN
		-- ########## INSTACIACAO DOS COMPONENTES ##########
		JOGADOR: personagem port map (
			signal_jogador_stateMov,
			signal_jogador_stateControl,
			signal_jogador_stateAction,
			signal_jogador_x,
			signal_jogador_y,
			signal_jogador_dead,
			signal_jogador_isAtacked,
			signal_jogador_isAtacking,
			signal_jogador_delayattacking,
			signal_jogador_energia,
			signal_jogador_moveSignal,
			signal_jogador_moveResponse,
			signal_jogador_moveDirection,
			signal_jogador_jumpSignal,
			signal_jogador_jumpResponse,
			clk,
			reset,
			signal_enable_global,
			signal_force_reset
		);
		
		-- TOCHAS
		TOCHA0: torchs port map(
			signal_torchs_state(0),
			signal_torchs_broken(0),
			signal_torchs_atacked(0),
			signal_torchs_x(0),
			signal_torchs_y(0),
			clk,
			reset,
			signal_enable_global
		);
		
		TOCHA1: torchs port map(
			signal_torchs_state(1),
			signal_torchs_broken(1),
			signal_torchs_atacked(1),
			signal_torchs_x(1),
			signal_torchs_y(1),
			clk,
			reset,
			signal_enable_global
		);

		TOCHA2: torchs port map(
			signal_torchs_state(2),
			signal_torchs_broken(2),
			signal_torchs_atacked(2),
			signal_torchs_x(2),
			signal_torchs_y(2),
			clk,
			reset,
			signal_enable_global
		);
		
		-- INIMIGOS
		INIMIGO0: enemy1 port map(
			signal_enemy_stateMov(0),
			signal_enemy_stateControl(0),
			signal_enemy_x(0),
			signal_enemy_y(0),
			signal_enemy_dead(0),
			signal_enemy_isAtacked(0),
			signal_enemy_direction(0),
			signal_enemy_energiaStart(0),
			signal_enemy_xStart(0),
			signal_enemy_yStart(0),
			clk,
			reset,
			signal_enable_global,
			signal_force_reset
		);
		
		INIMIGO1: enemy1 port map(
			signal_enemy_stateMov(1),
			signal_enemy_stateControl(1),
			signal_enemy_x(1),
			signal_enemy_y(1),
			signal_enemy_dead(1),
			signal_enemy_isAtacked(1),
			signal_enemy_direction(1),
			signal_enemy_energiaStart(1),
			signal_enemy_xStart(1),
			signal_enemy_yStart(1),
			clk,
			reset,
			signal_enable_global,
			signal_force_reset
		);
		
		INIMIGO2: enemy1 port map(
			signal_enemy_stateMov(2),
			signal_enemy_stateControl(2),
			signal_enemy_x(2),
			signal_enemy_y(2),
			signal_enemy_dead(2),
			signal_enemy_isAtacked(2),
			signal_enemy_direction(2),
			signal_enemy_energiaStart(2),
			signal_enemy_xStart(2),
			signal_enemy_yStart(2),
			clk,
			reset,
			signal_enable_global,
			signal_force_reset
		);
		
		INIMIGO3: enemy1 port map(
			signal_enemy_stateMov(3),
			signal_enemy_stateControl(3),
			signal_enemy_x(3),
			signal_enemy_y(3),
			signal_enemy_dead(3),
			signal_enemy_isAtacked(3),
			signal_enemy_direction(3),
			signal_enemy_energiaStart(3),
			signal_enemy_xStart(3),
			signal_enemy_yStart(3),
			clk,
			reset,
			signal_enable_global,
			signal_force_reset
		);
		
		INIMIGO4: enemy1 port map(
			signal_enemy_stateMov(4),
			signal_enemy_stateControl(4),
			signal_enemy_x(4),
			signal_enemy_y(4),
			signal_enemy_dead(4),
			signal_enemy_isAtacked(4),
			signal_enemy_direction(4),
			signal_enemy_energiaStart(4),
			signal_enemy_xStart(4),
			signal_enemy_yStart(4),
			clk,
			reset,
			signal_enable_global,
			signal_force_reset
		);
	
		-- PROCESS DE END GAME
		PROCESS(clk, reset, signal_enable_global) IS
			VARIABLE delay: integer := 2000000;
			BEGIN
			if (reset = '1') then
				signal_endgame <= '0';
				delay := 2000000;
			elsif (clk'event and clk = '1' and signal_enable_global = '1') then
				if (signal_jogador_dead = '1' or signal_win = '1') then
					delay := delay - 1;
				end if;
				if (delay = 0) then
					signal_endgame <= '1';
				end if;
			end if;
		END PROCESS;
		
		-- PROCESS DE ATTACK E SER ATACADO
		PROCESS(clk, reset, signal_enable_global) IS
			VARIABLE delay: integer := 0;
			BEGIN
			if (clk'event and clk = '1' and signal_enable_global = '1') then
				if (signal_enemy_dead(0) = '0' and signal_enemy_x(0) = signal_jogador_x and signal_enemy_y(0) = signal_jogador_y) then
					signal_jogador_isAtacked <= '1';
				elsif (signal_enemy_dead(1) = '0' and signal_enemy_x(1) = signal_jogador_x and signal_enemy_y(1) = signal_jogador_y) then
					signal_jogador_isAtacked <= '1';
				elsif (signal_enemy_dead(2) = '0' and signal_enemy_x(2) = signal_jogador_x and signal_enemy_y(2) = signal_jogador_y) then
					signal_jogador_isAtacked <= '1';
				elsif (signal_enemy_dead(3) = '0' and signal_enemy_x(3) = signal_jogador_x and signal_enemy_y(3) = signal_jogador_y) then
					signal_jogador_isAtacked <= '1';
				elsif (signal_enemy_dead(4) = '0' and signal_enemy_x(4) = signal_jogador_x and signal_enemy_y(4) = signal_jogador_y) then
					signal_jogador_isAtacked <= '1';
				else
					signal_jogador_isAtacked <= '0';
				end if;
				
				if (delay <= 0) then
					if (key_in = x"6B" and signal_jogador_isatacking = '0') theN
						delay := 50000;
						signal_jogador_isatacking <= '1';
						if (signal_jogador_y > 18) then
							if (signal_enemy_dead(0) = '0' and 
							((signal_jogador_x - signal_enemy_x(0) > 0 and signal_jogador_x - signal_enemy_x(0) <= 4 and signal_jogador_moveDirection = '1') 
							or(signal_enemy_x(0) - signal_jogador_x > 0 and signal_enemy_x(0) - signal_jogador_x <= 3 and signal_jogador_moveDirection = '0'))) then
								signal_enemy_isAtacked(0) <= '1';
							elsif (signal_enemy_dead(1) = '0' and 
							((signal_jogador_x - signal_enemy_x(1) > 0 and signal_jogador_x - signal_enemy_x(1) <= 4 and signal_jogador_moveDirection = '1') 
							or(signal_enemy_x(1) - signal_jogador_x > 0 and signal_enemy_x(1) - signal_jogador_x <= 3 and signal_jogador_moveDirection = '0'))) then
								signal_enemy_isAtacked(1) <= '1';
							elsif (signal_enemy_dead(2) = '0' and 
							((signal_jogador_x - signal_enemy_x(2) > 0 and signal_jogador_x - signal_enemy_x(2) <= 4 and signal_jogador_moveDirection = '1') 
							or(signal_enemy_x(2) - signal_jogador_x > 0 and signal_enemy_x(2) - signal_jogador_x <= 3 and signal_jogador_moveDirection = '0'))) then
								signal_enemy_isAtacked(2) <= '1';
							elsif (signal_enemy_dead(3) = '0' and 
							((signal_jogador_x - signal_enemy_x(3) > 0 and signal_jogador_x - signal_enemy_x(3) <= 4 and signal_jogador_moveDirection = '1') 
							or(signal_enemy_x(3) - signal_jogador_x > 0 and signal_enemy_x(3) - signal_jogador_x <= 3 and signal_jogador_moveDirection = '0'))) then
								signal_enemy_isAtacked(3) <= '1';
							elsif (signal_enemy_dead(4) = '0' and 
							((signal_jogador_x - signal_enemy_x(4) > 0 and signal_jogador_x - signal_enemy_x(4) <= 4 and signal_jogador_moveDirection = '1') 
							or(signal_enemy_x(4) - signal_jogador_x > 0 and signal_enemy_x(4) - signal_jogador_x <= 3 and signal_jogador_moveDirection = '0'))) then
								signal_enemy_isAtacked(4) <= '1';
							end if;
						end if;
					end if;
				else
					if (delay < 30000) then
						signal_jogador_isatacking <= '0';
					end if;
					signal_enemy_isAtacked(0) <= '0';
					signal_enemy_isAtacked(1) <= '0';
					signal_enemy_isAtacked(2) <= '0';
					signal_enemy_isAtacked(3) <= '0';
					signal_enemy_isAtacked(4) <= '0';
					delay := delay -1;
				end if;
			end if;
		END PROCESS;
		
		-- ENABLE GLOBAL
		PROCESS(clk, reset) IS
			VARIABLE key_start: STD_LOGIC_VECTOR(7 DOWNTO 0);
			VARIABLE load: STD_LOGIC := '0';
			BEGIN
			if (reset = '1') then 
				signal_enable_global <= '0';
				load := '0';
			elsif (clk'event and clk = '1' and signal_enable_global = '0') then
				if (load = '0') then
					key_start := key_in;
					load := '1';
				elsif(NOT(key_start = key_in)) then
					signal_enable_global <= '1';
				end if;
			end if;
		END PROCESS;
		
		-- ########## MAQUINAS DE ESTADO DO JOGO ##########
		-- MAQUINA DE ESTADO DE MOVIMENTO HORIZONTAL DE PERSONAGEM
		PROCESS (clk, reset, signal_enable_global) IS
			VARIABLE var_statePersonagemMov: STD_LOGIC_VECTOR(7 DOWNTO 0);
			VARIABLE var_statePersonagemMovIntermediario: STD_LOGIC_VECTOR(7 DOWNTO 0);
			BEGIN
			IF (reset = '1') then
				var_statePersonagemMov := x"00";
			elsif (clk'event and clk = '1' and signal_enable_global = '1') then
				
				case var_statePersonagemMov IS
					when x"01" =>
						var_statePersonagemMovIntermediario := x"02"; -- VAI P/ ESTADO DE MOV. DE JOGADOR GERAL
					when x"02" =>
						if (key_in = x"61") then -- TECLA 'A'
							var_statePersonagemMovIntermediario := x"AE"; -- VAI PARA ESTADO DE MOV A ESQUERDA
						elsif (key_in = x"64") then -- TECLA 'D'
							var_statePersonagemMovIntermediario := x"AD"; -- VAI PARA ESTADO DE MOV A DIREITA
						end if;
					when x"AE" =>
						var_statePersonagemMovIntermediario := x"AF";
					when x"AD" =>
						var_statePersonagemMovIntermediario := x"AF";
					when x"AF" =>
						var_statePersonagemMovIntermediario := x"02";
					when others =>
						var_statePersonagemMovIntermediario := x"01"; -- VAI PARA O ESTADO DE DEBUG
				END CASE;
				
				var_statePersonagemMov := var_statePersonagemMovIntermediario;
				
				CASE var_statePersonagemMov IS
					when x"01" => -- ESTADO DE RESET
						signal_jogador_moveSignal <= "00"; -- RESETA MOVE SIGNAL DO JOGADOR
					when x"02" => -- ESTADO DE MOV. DE JOGADOR GERAL
						signal_jogador_moveSignal <= "00"; -- CANCELA SINAL DE MOVIMENTO DO JOGADOR
						-- MOVE SIGNAL: 
							--		00 = NO MOVEMENT, 
							--		01 = TO THE LEFT, 
							--		10 = TO THE RIGHT, 
							--		11 = NO MOVEMENT
					when x"AE" => -- ESTADO DE MOV A ESQUERDA
						signal_jogador_moveSignal <= "01"; -- ENVIA SINAL PARA O JOGADOR ANDAR A ESQUERDA
					when x"AD" => -- ESTADO DE MOV A ESQUERDA
						signal_jogador_moveSignal <= "10"; -- ENVIA SINAL PARA O JOGADOR ANDAR A DIREITA
					when x"AF" =>
					when others => -- ESTADO DE DEBUG
						var_statePersonagemMov := x"01"; -- VAI PARA O ESTADO DE DEBUG
				END CASE;
			END IF;
		END PROCESS;
		
		-- MAQUINA DE ESTADO DE MOVIMENTO VERTICAL DE PERSONAGEM
		PROCESS (clk, reset, signal_enable_global) IS
			VARIABLE var_personagemPulo: STD_LOGIC_VECTOR(7 DOWNTO 0);
			BEGIN
			IF (reset = '1') then
				var_personagemPulo := x"00";
			elsif (clk'event and clk = '1' and signal_enable_global = '1') then
				CASE var_personagemPulo IS
					when x"01" => -- ESTADO DE RESET
						signal_jogador_jumpSignal <= '0'; -- RESETA JUMP SIGNAL DE JOGADOR
						var_personagemPulo := x"02"; -- VAI P/ ESTADO DE MOV. DE JOGADOR GERAL
					when x"02" => -- ESTADO DE MOV. DE JOGADOR GERAL
						signal_jogador_jumpSignal <= '0';
						if (signal_jogador_jumpResponse = '0' and key_in = x"77") then
							var_personagemPulo := x"B0"; -- VAI PARA ESTADO DE PULO
						end if;
					when x"B0" => -- ESTADO DE PULO IN
						signal_jogador_jumpSignal <= '1'; -- ENVIA SINAL PARA JOGADOR PULAR
						var_personagemPulo := x"B1"; -- AVANCA O ESTADO
					when x"B1" => -- ESTADO DE PULO OUT
						var_personagemPulo := x"02";
					when others => -- ESTADO DE DEBUG
						var_personagemPulo := x"01"; -- VAI PARA O ESTADO DE DEBUG
				END CASE;
			END IF;
		END PROCESS;
		
		-- MÁQUINA DE ESTADO PARA PRINTAR
		PROCESS(clk, reset, signal_enable_global) IS
			-- VARIAVEIS DE ESTADO DE PRINT
			VARIABLE var_statePrint: STD_LOGIC_VECTOR(7 DOWNTO 0) := x"00";
			VARIABLE var_statePrintIntermediario: STD_LOGIC_VECTOR(7 DOWNTO 0);
			CONSTANT FOURTH : UNSIGNED(7 DOWNTO 0) := x"28";
			--CONSTANT ASCIIZERO : UNSIGNED(7 DOWNTO 0) := x"C0";
			CONSTANT ASCIIZERO : UNSIGNED(7 DOWNTO 0) := x"B0";
			VARIABLE hp_counter: integer;
			VARIABLE counter : integer := 1199;
			VARIABLE delay : integer;
			VARIABLE reprint : integer;
			VARIABLE trovaodelay: integer;
			VARIABLE i, j: integer;
			
			BEGIN
			if (reset = '1') THEN 
				var_statePrint := x"00";
			elsif (clk'event and clk = '1' and delay <= 0) THEN
				if (signal_endgame = '1') then
					-- END-GAME STATE MACHINE
					CASE var_statePrint is
						when x"01" =>
							var_statePrintIntermediario := x"02";
						when x"02" =>
							var_statePrintIntermediario := x"03";
						when x"03" =>
							if (i < 1200) then
								var_statePrintIntermediario := x"02";
							else
								var_statePrintIntermediario := x"04";
							end if;
						when x"04" =>
						when others => 
							var_statePrintIntermediario := x"01";
					END CASE;
					
					var_statePrint := var_statePrintIntermediario;
					
					CASE var_statePrint IS
						when x"01" =>
							i := 0;
						when x"02" =>
							vga_pos <= conv_std_logic_vector(i , 16);
							
							if (signal_win = '1') then
								vga_char(15 DOWNTO 12) <= x"0";
								vga_char(11 DOWNTO 8) <= x"B";
								case i is
									-- YOU DID IT!
									when 480 + 15 + 0 => vga_char(7 DOWNTO 0) <= x"59";
									when 480 + 15 + 1 => vga_char(7 DOWNTO 0) <= x"4F";
									when 480 + 15 + 2 => vga_char(7 DOWNTO 0) <= x"55";
									
									when 480 + 15 + 4 => vga_char(7 DOWNTO 0) <= x"44";
									when 480 + 15 + 5 => vga_char(7 DOWNTO 0) <= x"49";
									when 480 + 15 + 6 => vga_char(7 DOWNTO 0) <= x"44";
									
									when 480 + 15 + 8 => vga_char(7 DOWNTO 0) <= x"49";
									when 480 + 15 + 9 => vga_char(7 DOWNTO 0) <= x"54";
									when 480 + 15 + 10 => vga_char(7 DOWNTO 0) <= x"21";
									
									-- BUT DRACULA IS IN
									
									when 520 + 11 + 0 => vga_char(7 DOWNTO 0) <= x"42";
									when 520 + 11 + 1 => vga_char(7 DOWNTO 0) <= x"55";
									when 520 + 11 + 2 => vga_char(7 DOWNTO 0) <= x"54";
									
									when 520 + 11 + 4 => vga_char(7 DOWNTO 0) <= x"44";
									when 520 + 11 + 5 => vga_char(7 DOWNTO 0) <= x"52";
									when 520 + 11 + 6 => vga_char(7 DOWNTO 0) <= x"41";
									when 520 + 11 + 7 => vga_char(7 DOWNTO 0) <= x"43";
									when 520 + 11 + 8 => vga_char(7 DOWNTO 0) <= x"55";
									when 520 + 11 + 9 => vga_char(7 DOWNTO 0) <= x"4C";
									when 520 + 11 + 10 => vga_char(7 DOWNTO 0) <= x"41";
									
									when 520 + 11 + 12 => vga_char(7 DOWNTO 0) <= x"49";
									when 520 + 11 + 13 => vga_char(7 DOWNTO 0) <= x"53";
									
									when 520 + 11 + 15 => vga_char(7 DOWNTO 0) <= x"49";
									when 520 + 11 + 16 => vga_char(7 DOWNTO 0) <= x"4E";
									
									-- ANOTHER CASTLE :[
									
									when 560 + 11 + 0 => vga_char(7 DOWNTO 0) <= x"41";
									when 560 + 11 + 1 => vga_char(7 DOWNTO 0) <= x"4E";
									when 560 + 11 + 2 => vga_char(7 DOWNTO 0) <= x"4F";
									when 560 + 11 + 3 => vga_char(7 DOWNTO 0) <= x"54";
									when 560 + 11 + 4 => vga_char(7 DOWNTO 0) <= x"48";
									when 560 + 11 + 5 => vga_char(7 DOWNTO 0) <= x"45";
									when 560 + 11 + 6 => vga_char(7 DOWNTO 0) <= x"52";
									
									when 560 + 11 + 8 => vga_char(7 DOWNTO 0) <= x"43";
									when 560 + 11 + 9 => vga_char(7 DOWNTO 0) <= x"41";
									when 560 + 11 + 10 => vga_char(7 DOWNTO 0) <= x"53";
									when 560 + 11 + 11 => vga_char(7 DOWNTO 0) <= x"54";
									when 560 + 11 + 12 => vga_char(7 DOWNTO 0) <= x"4C";
									when 560 + 11 + 13 => vga_char(7 DOWNTO 0) <= x"45";
									
									when 560 + 11 + 15 => vga_char(7 DOWNTO 0) <= x"3A";
									when 560 + 11 + 16 => vga_char(7 DOWNTO 0) <= x"5B";
									
									-- THE END!
									
									when 640 + 17 + 0 => vga_char(7 DOWNTO 0) <= x"54";
									when 640 + 17 + 1 => vga_char(7 DOWNTO 0) <= x"48";
									when 640 + 17 + 2 => vga_char(7 DOWNTO 0) <= x"45";
									
									when 640 + 17 + 4 => vga_char(7 DOWNTO 0) <= x"45";
									when 640 + 17 + 5 => vga_char(7 DOWNTO 0) <= x"4E";
									when 640 + 17 + 6 => vga_char(7 DOWNTO 0) <= x"44";
									when 640 + 17 + 7 => vga_char(7 DOWNTO 0) <= x"21";
									
									when others =>
										vga_char <= x"007E";
								end case;
							else
								vga_char(15 DOWNTO 12) <= x"0";
								vga_char(11 DOWNTO 8) <= x"9";
								case i is
									-- GAME IS OVER!
									when 600 + 14 + 0 => vga_char(7 DOWNTO 0) <= x"47";
									when 600 + 14 + 1 => vga_char(7 DOWNTO 0) <= x"41";
									when 600 + 14 + 2 => vga_char(7 DOWNTO 0) <= x"4D";
									when 600 + 14 + 3 => vga_char(7 DOWNTO 0) <= x"45";
									
									when 600 + 14 + 5 => vga_char(7 DOWNTO 0) <= x"49";
									when 600 + 14 + 6 => vga_char(7 DOWNTO 0) <= x"53";
									
									when 600 + 14 + 8 => vga_char(7 DOWNTO 0) <= x"4F";
									when 600 + 14 + 9 => vga_char(7 DOWNTO 0) <= x"56";
									when 600 + 14 + 10 => vga_char(7 DOWNTO 0) <= x"45";
									when 600 + 14 + 11 => vga_char(7 DOWNTO 0) <= x"52";
									when 600 + 14 + 12 => vga_char(7 DOWNTO 0) <= x"21";
									when others =>
										vga_char <= x"007E";
								end case;
							end if;
							
							vga_write <= '1';
						when x"03" =>
							vga_write <= '0';
							i := i + 1;
						when x"04" =>
						when others =>
							var_statePrint := x"01";
					END CASE;
					
				elsif (signal_enable_global = '1') then
					CASE var_statePrint IS
						when x"01" =>
							var_statePrintIntermediario:= x"02";
						when x"02" =>
							if (counter > 0) theN
								var_statePrintIntermediario:= x"03";
							else
								var_statePrintIntermediario:= x"05";
							end if;	
						when x"03" =>
							var_statePrintIntermediario:= x"02";
						when x"05" =>
							var_statePrintIntermediario:= x"06";
						when x"06" =>
							if (counter > 0) theN
								var_statePrintIntermediario:= x"07";
							else
								var_statePrintIntermediario:= x"08";
							end if;
						when x"07" =>
							var_statePrintIntermediario:= x"06";
						when x"08" =>
							var_statePrintIntermediario:= x"09";
						when x"09" =>
							if (i < 919) then
								var_statePrintIntermediario:= x"0A";
							else
								var_statePrintIntermediario:= x"0B";
							end if;
						when x"0A" =>
							var_statePrintIntermediario:= x"09";
						when x"0B" =>
							var_statePrintIntermediario := x"0C";
						when x"0C" =>
							if (i < 1200) then
								var_statePrintIntermediario := x"0D";
							else
								var_statePrintIntermediario := x"0E";
							end if;
						when x"0D" =>
							var_statePrintIntermediario:= x"0C";
						when x"0E" =>
							var_statePrintIntermediario:= x"0F";
						when x"0F" =>
							if (i < 880) then
								var_statePrintIntermediario:= x"10";
							else
								var_statePrintIntermediario:= x"A2";
							end if;
						WHEN X"10" =>
							var_statePrintIntermediario:= x"0F";
						when x"A2" =>
							if (hp_counter < 15) then
								var_statePrintIntermediario:= x"A3";
							else
								var_statePrintIntermediario:= x"A4";
							end if;
						when x"A3" =>
							var_statePrintIntermediario:= x"A2";
						when x"A4" =>
							var_statePrintIntermediario:= x"A5";
						when x"A5" =>
							if (i > 6) then
								var_statePrintIntermediario:= x"A6";
							else
								var_statePrintIntermediario:= x"A4";
							end if;
						when x"A6" =>
							var_statePrintIntermediario:= x"B0";
						when x"B0" =>
							var_statePrintIntermediario:= x"B1";
						when x"B1" =>
							if (j < 4) then
								var_statePrintIntermediario := x"B0";
							else
								var_statePrintIntermediario := x"B2";
							end if;
						when x"B2" =>
							var_statePrintIntermediario:= x"0E";
						when others =>
							var_statePrintIntermediario:= x"01";
					END CASE;
					var_statePrint := var_statePrintIntermediario;
					CASE var_statePrint IS
						-- BACKGROUND
						when x"01" =>
							trovaodelay := 0;
							counter := 1199;
							delay := 0;
							i := 0;
							hp_counter := 0;
						when x"02" =>
							vga_pos <= conv_std_logic_vector(i, 16);
							vga_char <= x"047D";
							i := i + 1;
							counter := counter - 1;
							vga_write <= '1';
						when x"03" =>
							vga_write <= '0';
						when x"05" => 
							i := 0;
							counter := 136;
						when x"06" =>
							vga_pos <= conv_std_logic_vector(i, 16);
							vga_write <= '1';
							vga_char <= x"007E";
							if (counter > 97) theN
								i := i + 1;
							elsif (counter > 68 and counter <= 97) then
								i := i + 40;
							elsif (counter > 29 and counter <= 68) then
								i := i - 1;
							else
								i := i - 40;
							end if;
							counter := counter - 1;
						when x"07" =>
							vga_write <= '0';
						when x"08" =>
							i := 881;
						when x"09" =>
							vga_pos <= conv_std_logic_vector(i, 16);
							vga_write <= '1';
							vga_char <= x"017C";
							i := i + 1;
						when x"0A" =>
							vga_write <= '0';
						when x"0B" =>
							i := i + 1;
						when x"0C" =>
							vga_pos <= conv_std_logic_vector(i, 16);
							vga_write <= '1';
							vga_char <= x"007E";
							i := i + 1;
						when x"0D" =>
							vga_write <= '0';
							
						
						-- REPRINT
						when x"0E" =>
							reprint := 0;
							i := 441;
							hp_counter := 0;
						when x"0F" =>
							-- PADRAO: BACKGROUND
							vga_char <= x"047D";
							
							-- NEXT LEVEL DOOR
							if (i = 851 - 2*40 - 1) then
								vga_char <= x"0577";
								if (signal_enemy_dead = "11111") then
									vga_char(11 DOWNTO 8) <= x"0";
								end if;
							end if;
							
							if (i = 851 - 2*40 - 0) then
								vga_char <= x"0578";
								if (signal_enemy_dead = "11111") then
									vga_char(11 DOWNTO 8) <= x"0";
								end if;
							end if;
							
							if (i = 851 - 40 - 1) then
								vga_char <= x"0579";
								if (signal_enemy_dead = "11111") then
									vga_char(11 DOWNTO 8) <= x"0";
								end if;
							end if;
							
							if (i = 851 - 40 - 0) then
								vga_char <= x"057A";
								if (signal_enemy_dead = "11111") then
									vga_char(11 DOWNTO 8) <= x"0";
								end if;
							end if;
							
							if (i = 851 - 1) then
								vga_char <= x"0579";
								if (signal_enemy_dead = "11111") then
									vga_char(11 DOWNTO 8) <= x"0";
								end if;
							end if;
							
							if (i = 851 - 0) then
								vga_char <= x"057A";
								if (signal_enemy_dead = "11111") then
									vga_char(11 DOWNTO 8) <= x"0";
								end if;
							end if;
							
							-- INIMIGO 0
							if (signal_enemy_dead(0) = '0') then 
								if (signal_enemy_direction(0) = '1') then
									if (UNsigned(signal_enemy_x(0)) - 1 + (UNsigned(signal_enemy_y(0)) - 2)*FOURTH = i) then
										vga_char <= x"0F22";
									elsif (UNsigned(signal_enemy_x(0)) - 0 + (UNsigned(signal_enemy_y(0)) - 2)*FOURTH = i) then
										vga_char <= x"0F23";
									elsif (UNsigned(signal_enemy_x(0)) - 1 + (UNsigned(signal_enemy_y(0)) - 1)*FOURTH = i) then
										vga_char <= x"0F24";
									elsif (UNsigned(signal_enemy_x(0)) - 0 + (UNsigned(signal_enemy_y(0)) - 1)*FOURTH = i) then
										vga_char <= x"0F25";
									elsif (UNsigned(signal_enemy_x(0)) - 1 + (UNsigned(signal_enemy_y(0)) - 0)*FOURTH = i) then
										vga_char <= x"0F26";
									elsif (UNsigned(signal_enemy_x(0)) - 0 + (UNsigned(signal_enemy_y(0)) - 0)*FOURTH = i) then
										vga_char <= x"0F27";
									end if;
								else
									if (UNsigned(signal_enemy_x(0)) - 1 + (UNsigned(signal_enemy_y(0)) - 2)*FOURTH = i) then
										vga_char <= x"0F28";
									elsif (UNsigned(signal_enemy_x(0)) - 0 + (UNsigned(signal_enemy_y(0)) - 2)*FOURTH = i) then
										vga_char <= x"0F29";
									elsif (UNsigned(signal_enemy_x(0)) - 1 + (UNsigned(signal_enemy_y(0)) - 1)*FOURTH = i) then
										vga_char <= x"0F2A";
									elsif (UNsigned(signal_enemy_x(0)) - 0 + (UNsigned(signal_enemy_y(0)) - 1)*FOURTH = i) then
										vga_char <= x"0F2B";
									elsif (UNsigned(signal_enemy_x(0)) - 1 + (UNsigned(signal_enemy_y(0)) - 0)*FOURTH = i) then
										vga_char <= x"0F2C";
									elsif (UNsigned(signal_enemy_x(0)) - 0 + (UNsigned(signal_enemy_y(0)) - 0)*FOURTH = i) then
										vga_char <= x"0F2D";
									end if;
								end if;
							elsif (UNsigned(signal_enemy_x(0)) - 0 + (UNsigned(signal_enemy_y(0)) - 0)*FOURTH = i) then
								vga_char <= x"0F12";
							end if;
							
							-- INIMIGO 1
							if (signal_enemy_dead(1) = '0') then 
								if (signal_enemy_direction(1) = '1') then
									if (UNsigned(signal_enemy_x(1)) - 1 + (UNsigned(signal_enemy_y(1)) - 2)*FOURTH = i) then
										vga_char <= x"0F13";
									elsif (UNsigned(signal_enemy_x(1)) - 0 + (UNsigned(signal_enemy_y(1)) - 2)*FOURTH = i) then
										vga_char <= x"0F14";
									elsif (UNsigned(signal_enemy_x(1)) - 1 + (UNsigned(signal_enemy_y(1)) - 1)*FOURTH = i) then
										vga_char <= x"0F15";
									elsif (UNsigned(signal_enemy_x(1)) - 0 + (UNsigned(signal_enemy_y(1)) - 1)*FOURTH = i) then
										vga_char <= x"0F16";
									elsif (UNsigned(signal_enemy_x(1)) - 1 + (UNsigned(signal_enemy_y(1)) - 0)*FOURTH = i) then
										vga_char <= x"0F17";
									elsif (UNsigned(signal_enemy_x(1)) - 0 + (UNsigned(signal_enemy_y(1)) - 0)*FOURTH = i) then
										vga_char <= x"0F18";
									end if;
								else
									if (UNsigned(signal_enemy_x(1)) - 1 + (UNsigned(signal_enemy_y(1)) - 2)*FOURTH = i) then
										vga_char <= x"0F19";
									elsif (UNsigned(signal_enemy_x(1)) - 0 + (UNsigned(signal_enemy_y(1)) - 2)*FOURTH = i) then
										vga_char <= x"0F1A";
									elsif (UNsigned(signal_enemy_x(1)) - 1 + (UNsigned(signal_enemy_y(1)) - 1)*FOURTH = i) then
										vga_char <= x"0F1B";
									elsif (UNsigned(signal_enemy_x(1)) - 0 + (UNsigned(signal_enemy_y(1)) - 1)*FOURTH = i) then
										vga_char <= x"0F1C";
									elsif (UNsigned(signal_enemy_x(1)) - 1 + (UNsigned(signal_enemy_y(1)) - 0)*FOURTH = i) then
										vga_char <= x"0F1D";
									elsif (UNsigned(signal_enemy_x(1)) - 0 + (UNsigned(signal_enemy_y(1)) - 0)*FOURTH = i) then
										vga_char <= x"0F1E";
									end if;
								end if;
							elsif (UNsigned(signal_enemy_x(1)) - 0 + (UNsigned(signal_enemy_y(1)) - 0)*FOURTH = i) then
								vga_char <= x"0F12";
							end if;
							
							-- INIMIGO 2
							if (signal_enemy_dead(2) = '0') then 
								if (signal_enemy_direction(2) = '1') then
									if (UNsigned(signal_enemy_x(2)) - 1 + (UNsigned(signal_enemy_y(2)) - 2)*FOURTH = i) then
										vga_char <= x"0F22";
									elsif (UNsigned(signal_enemy_x(2)) - 0 + (UNsigned(signal_enemy_y(2)) - 2)*FOURTH = i) then
										vga_char <= x"0F23";
									elsif (UNsigned(signal_enemy_x(2)) - 1 + (UNsigned(signal_enemy_y(2)) - 1)*FOURTH = i) then
										vga_char <= x"0F24";
									elsif (UNsigned(signal_enemy_x(2)) - 0 + (UNsigned(signal_enemy_y(2)) - 1)*FOURTH = i) then
										vga_char <= x"0F25";
									elsif (UNsigned(signal_enemy_x(2)) - 1 + (UNsigned(signal_enemy_y(2)) - 0)*FOURTH = i) then
										vga_char <= x"0F26";
									elsif (UNsigned(signal_enemy_x(2)) - 0 + (UNsigned(signal_enemy_y(2)) - 0)*FOURTH = i) then
										vga_char <= x"0F27";
									end if;
								else
									if (UNsigned(signal_enemy_x(2)) - 1 + (UNsigned(signal_enemy_y(2)) - 2)*FOURTH = i) then
										vga_char <= x"0F28";
									elsif (UNsigned(signal_enemy_x(2)) - 0 + (UNsigned(signal_enemy_y(2)) - 2)*FOURTH = i) then
										vga_char <= x"0F29";
									elsif (UNsigned(signal_enemy_x(2)) - 1 + (UNsigned(signal_enemy_y(2)) - 1)*FOURTH = i) then
										vga_char <= x"0F2A";
									elsif (UNsigned(signal_enemy_x(2)) - 0 + (UNsigned(signal_enemy_y(2)) - 1)*FOURTH = i) then
										vga_char <= x"0F2B";
									elsif (UNsigned(signal_enemy_x(2)) - 1 + (UNsigned(signal_enemy_y(2)) - 0)*FOURTH = i) then
										vga_char <= x"0F2C";
									elsif (UNsigned(signal_enemy_x(2)) - 0 + (UNsigned(signal_enemy_y(2)) - 0)*FOURTH = i) then
										vga_char <= x"0F2D";
									end if;
								end if;
							elsif (UNsigned(signal_enemy_x(2)) - 0 + (UNsigned(signal_enemy_y(2)) - 0)*FOURTH = i) then
								vga_char <= x"0F12";
							end if;
							
							-- INIMIGO 3
							if (signal_enemy_dead(3) = '0') then 
								if (signal_enemy_direction(3) = '1') then
									if (UNsigned(signal_enemy_x(3)) - 1 + (UNsigned(signal_enemy_y(3)) - 2)*FOURTH = i) then
										vga_char <= x"0F13";
									elsif (UNsigned(signal_enemy_x(3)) - 0 + (UNsigned(signal_enemy_y(3)) - 2)*FOURTH = i) then
										vga_char <= x"0F14";
									elsif (UNsigned(signal_enemy_x(3)) - 1 + (UNsigned(signal_enemy_y(3)) - 1)*FOURTH = i) then
										vga_char <= x"0F15";
									elsif (UNsigned(signal_enemy_x(3)) - 0 + (UNsigned(signal_enemy_y(3)) - 1)*FOURTH = i) then
										vga_char <= x"0F16";
									elsif (UNsigned(signal_enemy_x(3)) - 1 + (UNsigned(signal_enemy_y(3)) - 0)*FOURTH = i) then
										vga_char <= x"0F17";
									elsif (UNsigned(signal_enemy_x(3)) - 0 + (UNsigned(signal_enemy_y(3)) - 0)*FOURTH = i) then
										vga_char <= x"0F18";
									end if;
								else
									if (UNsigned(signal_enemy_x(3)) - 1 + (UNsigned(signal_enemy_y(3)) - 2)*FOURTH = i) then
										vga_char <= x"0F19";
									elsif (UNsigned(signal_enemy_x(3)) - 0 + (UNsigned(signal_enemy_y(3)) - 2)*FOURTH = i) then
										vga_char <= x"0F1A";
									elsif (UNsigned(signal_enemy_x(3)) - 1 + (UNsigned(signal_enemy_y(3)) - 1)*FOURTH = i) then
										vga_char <= x"0F1B";
									elsif (UNsigned(signal_enemy_x(3)) - 0 + (UNsigned(signal_enemy_y(3)) - 1)*FOURTH = i) then
										vga_char <= x"0F1C";
									elsif (UNsigned(signal_enemy_x(3)) - 1 + (UNsigned(signal_enemy_y(3)) - 0)*FOURTH = i) then
										vga_char <= x"0F1D";
									elsif (UNsigned(signal_enemy_x(3)) - 0 + (UNsigned(signal_enemy_y(3)) - 0)*FOURTH = i) then
										vga_char <= x"0F1E";
									end if;
								end if;
							elsif (UNsigned(signal_enemy_x(3)) - 0 + (UNsigned(signal_enemy_y(3)) - 0)*FOURTH = i) then
								vga_char <= x"0F12";
							end if;
							
							-- INIMIGO 4
							if (signal_enemy_dead(4) = '0') then 
								if (signal_enemy_direction(4) = '1') then
									if (UNsigned(signal_enemy_x(4)) - 1 + (UNsigned(signal_enemy_y(4)) - 2)*FOURTH = i) then
										vga_char <= x"0F13";
									elsif (UNsigned(signal_enemy_x(4)) - 0 + (UNsigned(signal_enemy_y(4)) - 2)*FOURTH = i) then
										vga_char <= x"0F14";
									elsif (UNsigned(signal_enemy_x(4)) - 1 + (UNsigned(signal_enemy_y(4)) - 1)*FOURTH = i) then
										vga_char <= x"0F15";
									elsif (UNsigned(signal_enemy_x(4)) - 0 + (UNsigned(signal_enemy_y(4)) - 1)*FOURTH = i) then
										vga_char <= x"0F16";
									elsif (UNsigned(signal_enemy_x(4)) - 1 + (UNsigned(signal_enemy_y(4)) - 0)*FOURTH = i) then
										vga_char <= x"0F17";
									elsif (UNsigned(signal_enemy_x(4)) - 0 + (UNsigned(signal_enemy_y(4)) - 0)*FOURTH = i) then
										vga_char <= x"0F18";
									end if;
								else
									if (UNsigned(signal_enemy_x(4)) - 1 + (UNsigned(signal_enemy_y(4)) - 2)*FOURTH = i) then
										vga_char <= x"0F19";
									elsif (UNsigned(signal_enemy_x(4)) - 0 + (UNsigned(signal_enemy_y(4)) - 2)*FOURTH = i) then
										vga_char <= x"0F1A";
									elsif (UNsigned(signal_enemy_x(4)) - 1 + (UNsigned(signal_enemy_y(4)) - 1)*FOURTH = i) then
										vga_char <= x"0F1B";
									elsif (UNsigned(signal_enemy_x(4)) - 0 + (UNsigned(signal_enemy_y(4)) - 1)*FOURTH = i) then
										vga_char <= x"0F1C";
									elsif (UNsigned(signal_enemy_x(4)) - 1 + (UNsigned(signal_enemy_y(4)) - 0)*FOURTH = i) then
										vga_char <= x"0F1D";
									elsif (UNsigned(signal_enemy_x(4)) - 0 + (UNsigned(signal_enemy_y(4)) - 0)*FOURTH = i) then
										vga_char <= x"0F1E";
									end if;
								end if;
							elsif (UNsigned(signal_enemy_x(4)) - 0 + (UNsigned(signal_enemy_y(4)) - 0)*FOURTH = i) then
								vga_char <= x"0F12";
							end if;
							
							-- JOGADOR (stand)
							if (signal_jogador_dead = '0') then
								if (signal_jogador_moveDirection = '0') then
									if (NOT(signal_jogador_delayattacking = 0)) then
										if (UNsigned(signal_jogador_x) - 1 + (UNsigned(signal_jogador_y) - 2)*FOURTH = i) theN
											vga_char <= x"0F61";
										elsif (UNsigned(signal_jogador_x) - 0 + (UNsigned(signal_jogador_y) - 2)*FOURTH = i) then
											vga_char <= x"0F62";
										elsif (UNsigned(signal_jogador_x) - 1 + (UNsigned(signal_jogador_y) - 1)*FOURTH = i) then
											vga_char <= x"0F63";
										elsif (UNsigned(signal_jogador_x) - 0 + (UNsigned(signal_jogador_y) - 1)*FOURTH = i) then
											vga_char <= x"0F64";
										elsif (UNsigned(signal_jogador_x) - 1 + (UNsigned(signal_jogador_y) - 0)*FOURTH = i) then
											vga_char <= x"0F65";
										elsif (UNsigned(signal_jogador_x) - 0 + (UNsigned(signal_jogador_y) - 0)*FOURTH = i) then
											vga_char <= x"0F66";
										elsif (UNsigned(signal_jogador_x) + 1 + (UNsigned(signal_jogador_y) - 1)*FOURTH = i) then
											vga_char <= x"0F67";
										elsif (UNsigned(signal_jogador_x) + 2 + (UNsigned(signal_jogador_y) - 1)*FOURTH = i) then
											vga_char <= x"0F68";
										elsif (UNsigned(signal_jogador_x) + 3 + (UNsigned(signal_jogador_y) - 1)*FOURTH = i) then
											vga_char <= x"0F69";
										end if;
									elsif (signal_jogador_jumpResponse = '1') then
										if (UNsigned(signal_jogador_x) - 1 + (UNsigned(signal_jogador_y) - 2)*FOURTH = i) theN
											vga_char <= x"0F06";
										elsif (UNsigned(signal_jogador_x) - 0 + (UNsigned(signal_jogador_y) - 2)*FOURTH = i) then
											vga_char <= x"0F07";
										elsif (UNsigned(signal_jogador_x) - 1 + (UNsigned(signal_jogador_y) - 1)*FOURTH = i) then
											vga_char <= x"0F08";
										elsif (UNsigned(signal_jogador_x) - 0 + (UNsigned(signal_jogador_y) - 1)*FOURTH = i) then
											vga_char <= x"0F09";
										elsif (UNsigned(signal_jogador_x) - 1 + (UNsigned(signal_jogador_y) - 0)*FOURTH = i) then
											vga_char <= x"0F0A";
										elsif (UNsigned(signal_jogador_x) - 0 + (UNsigned(signal_jogador_y) - 0)*FOURTH = i) then
											vga_char <= x"0F0B";
										end if;
									else
										if (UNsigned(signal_jogador_x) - 1 + (UNsigned(signal_jogador_y) - 2)*FOURTH = i) theN
											vga_char <= x"0F3B";
										elsif (UNsigned(signal_jogador_x) - 0 + (UNsigned(signal_jogador_y) - 2)*FOURTH = i) then
											vga_char <= x"0F3C";
										elsif (UNsigned(signal_jogador_x) - 1 + (UNsigned(signal_jogador_y) - 1)*FOURTH = i) then
											vga_char <= x"0F3D";
										elsif (UNsigned(signal_jogador_x) - 0 + (UNsigned(signal_jogador_y) - 1)*FOURTH = i) then
											vga_char <= x"0F3E";
										elsif (UNsigned(signal_jogador_x) - 1 + (UNsigned(signal_jogador_y) - 0)*FOURTH = i) then
											vga_char <= x"0F3F";
										elsif (UNsigned(signal_jogador_x) - 0 + (UNsigned(signal_jogador_y) - 0)*FOURTH = i) then
											vga_char <= x"0F40";
										end if;
									end if;
								else
									if (NOT(signal_jogador_delayattacking = 0)) then
										if (UNsigned(signal_jogador_x) - 1 + (UNsigned(signal_jogador_y) - 2)*FOURTH = i) theN
											vga_char <= x"0F6A";
										elsif (UNsigned(signal_jogador_x) - 0 + (UNsigned(signal_jogador_y) - 2)*FOURTH = i) then
											vga_char <= x"0F6B";
										elsif (UNsigned(signal_jogador_x) - 1 + (UNsigned(signal_jogador_y) - 1)*FOURTH = i) then
											vga_char <= x"0F6C";
										elsif (UNsigned(signal_jogador_x) - 0 + (UNsigned(signal_jogador_y) - 1)*FOURTH = i) then
											vga_char <= x"0F6D";
										elsif (UNsigned(signal_jogador_x) - 1 + (UNsigned(signal_jogador_y) - 0)*FOURTH = i) then
											vga_char <= x"0F6E";
										elsif (UNsigned(signal_jogador_x) - 0 + (UNsigned(signal_jogador_y) - 0)*FOURTH = i) then
											vga_char <= x"0F6F";
										elsif (UNsigned(signal_jogador_x) - 2 + (UNsigned(signal_jogador_y) - 1)*FOURTH = i) then
											vga_char <= x"0F70";
										elsif (UNsigned(signal_jogador_x) - 3 + (UNsigned(signal_jogador_y) - 1)*FOURTH = i) then
											vga_char <= x"0F71";
										elsif (UNsigned(signal_jogador_x) - 4 + (UNsigned(signal_jogador_y) - 1)*FOURTH = i) then
											vga_char <= x"0F72";
										end if;
									elsif (signal_jogador_jumpResponse = '1') then
										if (UNsigned(signal_jogador_x) - 1 + (UNsigned(signal_jogador_y) - 2)*FOURTH = i) theN
											vga_char <= x"0F0C";
										elsif (UNsigned(signal_jogador_x) - 0 + (UNsigned(signal_jogador_y) - 2)*FOURTH = i) then
											vga_char <= x"0F0D";
										elsif (UNsigned(signal_jogador_x) - 1 + (UNsigned(signal_jogador_y) - 1)*FOURTH = i) then
											vga_char <= x"0F0E";
										elsif (UNsigned(signal_jogador_x) - 0 + (UNsigned(signal_jogador_y) - 1)*FOURTH = i) then
											vga_char <= x"0F0F";
										elsif (UNsigned(signal_jogador_x) - 1 + (UNsigned(signal_jogador_y) - 0)*FOURTH = i) then
											vga_char <= x"0F10";
										elsif (UNsigned(signal_jogador_x) - 0 + (UNsigned(signal_jogador_y) - 0)*FOURTH = i) then
											vga_char <= x"0F11";
										end if;
									else
										if (UNsigned(signal_jogador_x) - 1 + (UNsigned(signal_jogador_y) - 2)*FOURTH = i) theN
											vga_char <= x"0F00";
										elsif (UNsigned(signal_jogador_x) - 0 + (UNsigned(signal_jogador_y) - 2)*FOURTH = i) then
											vga_char <= x"0F01";
										elsif (UNsigned(signal_jogador_x) - 1 + (UNsigned(signal_jogador_y) - 1)*FOURTH = i) then
											vga_char <= x"0F02";
										elsif (UNsigned(signal_jogador_x) - 0 + (UNsigned(signal_jogador_y) - 1)*FOURTH = i) then
											vga_char <= x"0F03";
										elsif (UNsigned(signal_jogador_x) - 1 + (UNsigned(signal_jogador_y) - 0)*FOURTH = i) then
											vga_char <= x"0F04";
										elsif (UNsigned(signal_jogador_x) - 0 + (UNsigned(signal_jogador_y) - 0)*FOURTH = i) then
											vga_char <= x"0F05";
										end if;
									end if;
								end if;
							elsif (UNsigned(signal_jogador_x) - 0 + (UNsigned(signal_jogador_y) - 0)*FOURTH = i) then
								vga_char <= x"0F12";
							end if;
							
							vga_pos <= conv_std_logic_vector(i, 16);
							-- ANTI-BUG
							if (NOT(i MOD 40 = 0 or i MOD 40 = 39)) then
								vga_write <= '1';
							end if;
						when x"10" =>
							i := i + 1;
							vga_write <= '0';
							
						-- HUD
						-- ENERGIA DO PERSONAGEM
						when x"A2" => 
							if (signal_jogador_energia > hp_counter) then
								vga_char <= x"015C";
							else
								vga_char <= x"007E";
							end if;
							vga_pos <= conv_std_logic_vector(1013 + hp_counter, 16);
							vga_write <= '1';
							i := 0;
						when x"A3" =>
							vga_write <= '0';
							hp_counter := hp_counter + 1;
						-- FASES
						when x"A4" =>
							case i is
								when 0 =>
									vga_char <= x"0F53";
								when 1 =>
									vga_char <= x"0F54";
								when 2 =>
									vga_char <= x"0F41";
								when 3 =>
									vga_char <= x"0F47";
								when 4 =>
									vga_char <= x"0F45";
								when 5 =>
									vga_char <= x"0F3A";
								when 6 =>
									vga_char(15 DOWNTO 12) <= x"0";
									vga_char(11 DOWNTO 8) <= x"F";
									vga_char(7 DOWNTO 0) <= conv_std_logic_vector(unsigned(signal_fase) - unsigned(ASCIIZERO), 8);
								when others => 
							end case;
							vga_write <= '1';
							vga_pos <= conv_std_logic_vector(1053 + i, 16);
						when x"A5" =>
							i := i + 1;
							vga_write <= '0';
						
						when x"A6" => -- PREPARACAO DAS JANELAS
							counter := 0;
							i := ((3*40) + 8);
							j := 0;
							if (trovaodelay <= 0) then
								trovaodelay := 205;
							else
								trovaodelay := trovaodelay - 1;
							end if;
						when x"B0" =>  -- PRINT DAS JANELAS
							if ((trovaodelay >= 120 and trovaodelay <= 122) or (trovaodelay >= 124 and trovaodelay <= 126)) then
								vga_char(11 DOWNTO 8) <= x"F";
							else
								vga_char(11 DOWNTO 8) <= x"0";
							end if;
							vga_char(15 DOWNTO 12) <= x"0";
							vga_char(7 DOWNTO 0) <= x"7E";
							vga_pos <= conv_std_logic_vector(i + (40*counter), 16);
							vga_write <= '1';
						when x"B1" => -- WRITE OUT DAS JANELAS
							if (j < 4) then
								counter := counter + 1;
								if (counter = 7) then
									i := i + 8;
									counter := 0;
									j := j + 1;
								end if;
							end if;
							vga_write <= '0';
						when x"B2" => -- RE-LOOP
						when others =>
							var_statePrint := x"01";
					END CASE;
				else
					CASE var_statePrint is
						when x"E0" =>
							var_statePrintIntermediario := x"E1";
						when x"E1" => -- FUNDO PRETO 
							var_statePrintIntermediario := x"E2";
						when x"E2" => -- WRITE 0 do fundo preto
							if (i < 1200) then
								var_statePrintIntermediario := x"E1";
							else
								var_statePrintIntermediario := x"E3";
							end if;
						when x"E3" => -- PREP. DO TITULO DO JOGO
							var_statePrintIntermediario := x"E4";
						when x"E4" => -- TITULO DO JOGO
							var_statePrintIntermediario := x"E5";
						when x"E5" => -- WRITE 0 do titulo do jogo
							if (i < (10 * 40) + 15 + 11) then --OLDER VERSION (NO MOON)
								--if (i < (575)) then
								var_statePrintIntermediario := x"E4";
							else
								var_statePrintIntermediario := x"E6";
							end if;
							
						when x"E6" => -- "LOOP START HERE" PREP. DO PRESS ANY KEY
							var_statePrintIntermediario := x"E7";
						when x"E7" => -- "PRESS ANY KEY"
							var_statePrintIntermediario := x"E8";
						when x"E8" => -- WRITE 0 DO PRESS ANY KEY
							if (i < (20 * 40) + 14 + 13) then
								var_statePrintIntermediario := x"E7";
							else
								var_statePrintIntermediario := x"E9";
							end if;
						
						when x"E9" => -- RE-LOOP
							var_statePrintIntermediario := x"E6";
						when others =>
							var_statePrintIntermediario := x"E0";
					END CASE;
					
					var_statePrint := var_statePrintIntermediario;
					
					CASE var_statePrint is
						when x"E0" =>
							i := 0;
							counter := 0;
						when x"E1" => -- FUNDO PRETO 
							vga_char <= x"007E";
							vga_pos <= conv_std_logic_vector(i, 16);
							vga_write <= '1';
						when x"E2" => -- WRITE 0 do fundo preto
							i := i + 1;
							vga_write <= '0';
						
						when x"E3" => -- PREP. DO TITULO DO JOGO
							i := (10 * 40) + 15; --OLDER VERSION (NO MOON)
							--i := 294;
						when x"E4" => -- TITULO DO JOGO
							case i is
								when ((10 * 40) + 15 + 0) => vga_char <= x"0143"; -- C
								when ((10 * 40) + 15 + 1) => vga_char <= x"0141"; -- A
								when ((10 * 40) + 15 + 2) => vga_char <= x"0153"; -- S
								when ((10 * 40) + 15 + 3) => vga_char <= x"0154"; -- T
								when ((10 * 40) + 15 + 4) => vga_char <= x"014C"; -- L
								when ((10 * 40) + 15 + 5) => vga_char <= x"0145"; -- E
								when ((10 * 40) + 15 + 6) => vga_char <= x"0156"; -- V
								when ((10 * 40) + 15 + 7) => vga_char <= x"0141"; -- A
								when ((10 * 40) + 15 + 8) => vga_char <= x"014E"; -- N
								when ((10 * 40) + 15 + 9) => vga_char <= x"0149"; -- I
								when ((10 * 40) + 15 + 10) => vga_char <= x"0141"; -- A
								
								when others =>
							end case;
							vga_pos <= conv_std_logic_vector(i, 16);
							vga_write <= '1';
						when x"E5" => -- WRITE 0 do titulo do jogo
							i := i + 1;
							vga_write <= '0';
							
						when x"E6" => -- "LOOP START HERE" PREP. DO PRESS ANY KEY
							i := (20 * 40) + 14;
							if (counter <= 0) then
								counter := 20000;
							end if;
						when x"E7" => -- "PRESS ANY KEY"
							case i is
								when ((20 * 40) + 14 + 0) => vga_char(7 DOWNTO 0) <= x"50"; -- P
								when ((20 * 40) + 14 + 1) => vga_char(7 DOWNTO 0) <= x"52"; -- R
								when ((20 * 40) + 14 + 2) => vga_char(7 DOWNTO 0) <= x"45"; -- E
								when ((20 * 40) + 14 + 3) => vga_char(7 DOWNTO 0) <= x"53"; -- S
								when ((20 * 40) + 14 + 4) => vga_char(7 DOWNTO 0) <= x"53"; -- S
								when ((20 * 40) + 14 + 5) => vga_char(7 DOWNTO 0) <= x"20"; -- ' '
								when ((20 * 40) + 14 + 6) => vga_char(7 DOWNTO 0) <= x"41"; -- A
								when ((20 * 40) + 14 + 7) => vga_char(7 DOWNTO 0) <= x"4E"; -- N
								when ((20 * 40) + 14 + 8) => vga_char(7 DOWNTO 0) <= x"59"; -- Y
								when ((20 * 40) + 14 + 9) => vga_char(7 DOWNTO 0) <= x"20"; -- ' '
								when ((20 * 40) + 14 + 10) => vga_char(7 DOWNTO 0) <= x"4B"; -- K
								when ((20 * 40) + 14 + 11) => vga_char(7 DOWNTO 0) <= x"45"; -- E
								when ((20 * 40) + 14 + 12) => vga_char(7 DOWNTO 0) <= x"59"; -- Y
								when others =>
							end case;
							if (counter < 6000) then
								vga_char(11 DOWNTO 8) <= x"0";
							else
								vga_char(11 DOWNTO 8) <= x"F";
							end if;
							vga_char(15 DOWNTO 12) <= x"0";
							vga_pos <= conv_std_logic_vector(i, 16);
							vga_write <= '1';
						when x"E8" => -- WRITE 0 DO PRESS ANY KEY
							i := i + 1;
							vga_write <= '0';
							if (counter <= 0) then
								counter := 20000;
							else
								counter := counter - 1;
							end if;
						when x"E9" => -- RE-LOOP
						when others =>
							var_statePrint := x"E0";
					END CASE;
				END IF;
				
				if (var_statePrint <= x"0D") then
					delay := 10;
				else
					delay := 35;
				end if;
				
			END IF;
			delay := delay - 1;
		END PROCESS;
		
		-- MÁQUINA DE ESTADO DE CONTROLE DE FASES
		PROCESS(clk, reset, signal_enable_global) IS
			-- VARIABLES DA FASE
			VARIABLE var_stateFase: STD_LOGIC_VECTOR(7 DOWNTO 0) := x"00";
			VARIABLE var_stateFaseIntermediario: STD_LOGIC_VECTOR(7 DOWNTO 0) := x"00";
			BEGIN
			if (reset = '1') then 
				var_stateFase := x"00";
			elsif (clk'event and clk = '1' and signal_enable_global = '1') then
				case var_stateFase is
					when x"01" =>
						var_stateFaseIntermediario := x"F0"; -- VAI PARA A FASE NUMERO 0
					when x"F0" =>
						var_stateFaseIntermediario := x"D0";
					when x"F1" =>
						var_stateFaseIntermediario := x"D1";
					when x"F2" =>
						var_stateFaseIntermediario := x"D2";
					when x"F3" =>
						var_stateFaseIntermediario := x"D3";
					when x"F4" =>
						var_stateFaseIntermediario := x"D4";
					when x"F5" =>
						var_stateFaseIntermediario := x"D5";
						
					when x"E0" => 
						if (signal_enemy_dead = "11111" and signal_jogador_x = 11 and signal_jogador_y = 21) then
							var_stateFaseIntermediario := x"F1";
						end if;
					when x"E1" => 
						if (signal_enemy_dead = "11111" and signal_jogador_x = 11 and signal_jogador_y = 21) then
							var_stateFaseIntermediario := x"F2";
						end if;
					when x"E2" => 
						if (signal_enemy_dead = "11111" and signal_jogador_x = 11 and signal_jogador_y = 21) then
							var_stateFaseIntermediario := x"F3";
						end if;
					when x"E3" =>
						if (signal_enemy_dead = "11111" and signal_jogador_x = 11 and signal_jogador_y = 21) then
							var_stateFaseIntermediario := x"F4";
						end if;	
					when x"E4" => 
						if (signal_enemy_dead = "11111" and signal_jogador_x = 11 and signal_jogador_y = 21) then
							var_stateFaseIntermediario := x"F5";
						end if;
					when x"E5" =>
					
					when x"D0" =>
						var_stateFaseIntermediario := x"E0";
					when x"D1" =>
						var_stateFaseIntermediario := x"E1";
					when x"D2" =>
						var_stateFaseIntermediario := x"E2";
					when x"D3" =>
						var_stateFaseIntermediario := x"E3";
					when x"D4" =>
						var_stateFaseIntermediario := x"E4";
					when x"D5" =>
						var_stateFaseIntermediario := x"E5";
					
					when others =>
						var_stateFaseIntermediario := x"01"; -- VAI PARA O CASO DE RESET
				end case;
				
				var_stateFase := var_stateFaseIntermediario;
				
				case var_stateFase is
					when x"01" =>
						signal_enemy_xStart(0) <= x"00";
						signal_enemy_yStart(0) <= x"00";
						signal_enemy_energiaStart(0) <= x"1";
						signal_enemy_xStart(1) <= x"00";
						signal_enemy_yStart(1) <= x"00";
						signal_enemy_energiaStart(1) <= x"1";
						signal_enemy_xStart(2) <= x"00";
						signal_enemy_yStart(2) <= x"00";
						signal_enemy_energiaStart(2) <= x"1";
						signal_enemy_xStart(3) <= x"00";
						signal_enemy_yStart(3) <= x"00";
						signal_enemy_energiaStart(3) <= x"1";
						signal_enemy_xStart(4) <= x"00";
						signal_enemy_yStart(4) <= x"00";
						signal_enemy_energiaStart(4) <= x"1";
						
						signal_win <= '0';
						signal_force_reset <= '0';
					when x"F0" => -- FASE NUMERO 0
						-- INIMIGO 0
						signal_enemy_xStart(0) <= x"26";
						signal_enemy_yStart(0) <= x"15";
						signal_enemy_energiaStart(0) <= x"2";
						-- INIMIGO 1
						signal_enemy_xStart(1) <= x"04";
						signal_enemy_yStart(1) <= x"15";
						signal_enemy_energiaStart(1) <= x"2";
						-- INIMIGO 2
						signal_enemy_xStart(2) <= x"00";
						signal_enemy_yStart(2) <= x"00";
						signal_enemy_energiaStart(2) <= x"0";
						-- INIMIGO 3
						signal_enemy_xStart(3) <= x"00";
						signal_enemy_yStart(3) <= x"00";
						signal_enemy_energiaStart(3) <= x"0";
						-- INIMIGO 4
						signal_enemy_xStart(4) <= x"00";
						signal_enemy_yStart(4) <= x"00";
						signal_enemy_energiaStart(4) <= x"0";
						
						signal_force_reset <= '1';
					when x"F1" => -- FASE NUMERO 1
						-- INIMIGO 0
						signal_enemy_xStart(0) <= x"26";
						signal_enemy_yStart(0) <= x"15";
						signal_enemy_energiaStart(0) <= x"2";
						-- INIMIGO 1
						signal_enemy_xStart(1) <= x"04";
						signal_enemy_yStart(1) <= x"15";
						signal_enemy_energiaStart(1) <= x"2";
						-- INIMIGO 2
						signal_enemy_xStart(2) <= x"07";
						signal_enemy_yStart(2) <= x"15";
						signal_enemy_energiaStart(2) <= x"2";
						-- INIMIGO 3
						signal_enemy_xStart(3) <= x"00";
						signal_enemy_yStart(3) <= x"00";
						signal_enemy_energiaStart(3) <= x"0";
						-- INIMIGO 4
						signal_enemy_xStart(4) <= x"00";
						signal_enemy_yStart(4) <= x"00";
						signal_enemy_energiaStart(4) <= x"0";
					
						signal_force_reset <= '1';
					when x"F2" => -- FASE NUMERO 2
						-- INIMIGO 0
						signal_enemy_xStart(0) <= x"26";
						signal_enemy_yStart(0) <= x"15";
						signal_enemy_energiaStart(0) <= x"2";
						-- INIMIGO 1
						signal_enemy_xStart(1) <= x"04";
						signal_enemy_yStart(1) <= x"15";
						signal_enemy_energiaStart(1) <= x"2";
						-- INIMIGO 2
						signal_enemy_xStart(2) <= x"07";
						signal_enemy_yStart(2) <= x"15";
						signal_enemy_energiaStart(2) <= x"2";
						-- INIMIGO 3
						signal_enemy_xStart(3) <= x"24";
						signal_enemy_yStart(3) <= x"15";
						signal_enemy_energiaStart(3) <= x"3";
						-- INIMIGO 4
						signal_enemy_xStart(4) <= x"00";
						signal_enemy_yStart(4) <= x"00";
						signal_enemy_energiaStart(4) <= x"0";
					
						signal_force_reset <= '1';
					when x"F3" => -- FASE NUMERO 3
						-- INIMIGO 0
						signal_enemy_xStart(0) <= x"08";
						signal_enemy_yStart(0) <= x"15";
						signal_enemy_energiaStart(0) <= x"2";
						-- INIMIGO 1
						signal_enemy_xStart(1) <= x"04";
						signal_enemy_yStart(1) <= x"15";
						signal_enemy_energiaStart(1) <= x"2";
						-- INIMIGO 2
						signal_enemy_xStart(2) <= x"28";
						signal_enemy_yStart(2) <= x"15";
						signal_enemy_energiaStart(2) <= x"3";
						-- INIMIGO 3
						signal_enemy_xStart(3) <= x"23";
						signal_enemy_yStart(3) <= x"15";
						signal_enemy_energiaStart(3) <= x"3";
						-- INIMIGO 4
						signal_enemy_xStart(4) <= x"00";
						signal_enemy_yStart(4) <= x"00";
						signal_enemy_energiaStart(4) <= x"0";
					
						signal_force_reset <= '1';
					when x"F4" => -- FASE NUMERO 4
						-- INIMIGO 0
						signal_enemy_xStart(0) <= x"06";
						signal_enemy_yStart(0) <= x"15";
						signal_enemy_energiaStart(0) <= x"4";
						-- INIMIGO 1
						signal_enemy_xStart(1) <= x"03";
						signal_enemy_yStart(1) <= x"15";
						signal_enemy_energiaStart(1) <= x"4";
						-- INIMIGO 2
						signal_enemy_xStart(2) <= x"22";
						signal_enemy_yStart(2) <= x"15";
						signal_enemy_energiaStart(2) <= x"4";
						-- INIMIGO 3
						signal_enemy_xStart(3) <= x"26";
						signal_enemy_yStart(3) <= x"15";
						signal_enemy_energiaStart(3) <= x"4";
						-- INIMIGO 4
						signal_enemy_xStart(4) <= x"09";
						signal_enemy_yStart(4) <= x"15";
						signal_enemy_energiaStart(4) <= x"4";
					
						signal_force_reset <= '1';
					when x"F5" => -- END LEVEL
						signal_win <= '1';
						
					when x"E0" =>
					when x"E1" =>
					when x"E2" =>
					when x"E3" =>
					when x"E4" =>
					when x"E5" =>
					
					when x"D0" =>
						signal_force_reset <= '0';
					when x"D1" =>
						signal_force_reset <= '0';
					when x"D2" =>
						signal_force_reset <= '0';
					when x"D3" =>
						signal_force_reset <= '0';
					when x"D4" =>
						signal_force_reset <= '0';
					when x"D5" =>
						signal_force_reset <= '0';
					
					when others => -- CASO DE DEBUG
						var_stateFase := x"01"; -- VAI PARA O CASO DE RESET
				END CASE;
			END IF;
			-- ATUALIZA O SINAL EXTERNO DE ACORDO COM A VARIABLE
			signal_fase <= var_stateFase;
		END PROCESS;
END THE_GAME;