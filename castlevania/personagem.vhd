LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY personagem IS
	PORT(
	-- STATE SIGNALS
		state_mov		: OUT STD_LOGIC_VECTOR(7 downto 0);
		state_control	: OUT STD_LOGIC_VECTOR(7 downto 0);
		state_action	: OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
		state_jump		: OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
		
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
END personagem;


ARCHITECTURE player OF personagem IS
	-- SINAIS GLOBAIS RELEVANTES
	SIGNAL energia 		: UNSIGNED(7 DOWNTO 0) := x"0A"; -- ENERGIA VAI DE 0 A 15
	SIGNAL sig_x			: UNSIGNED(7 DOWNTO 0) := x"14"; -- X > [0, 40]
	SIGNAL sig_y			: UNSIGNED(7 DOWNTO 0) := x"15"; -- Y > [0, 30]
	SIGNAL sig_dir			: STD_LOGIC := '0'; -- INICIALIZA VIRADO PRA RIGHT
	SIGNAL sig_dead		: STD_LOGIC := '0'; -- INICIALIZA VIVO (UFA!)
BEGIN

		-- MAQUINA DE ESTADO DE PULO
		PROCESS(clk, reset, signal_force_reset)
			-- VARIAVEIS DE MOVIMENTO
			VARIABLE var_stateJump : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"00"; -- ESTADO DA MAQ. DE ESTADO DE MOV.
			VARIABLE var_stateIntermediateJump : std_LOGIC_VECTOR(7 DOWNTO 0) := x"00";
			VARIABLE var_y: INTEGER := to_integer(sig_y(7 DOWNTO 0)); -- INDICADOR DE POS Y
			VARIABLE jump: INTEGER := 0; -- JUMP [0 - 300000]
			
			BEGIN
			if (reset = '1' or signal_force_reset = '1') then
				var_stateJump := x"00";
			elsif (clk'event and '1' = clk) then
				case var_stateJump is
					when x"01" => -- ESTADO DE RESET
						if(sig_dead = '0' and jumpSignal = '1') then
							var_stateintermediateJump := x"02";
						end if;
					when x"02" => 
						var_stateintermediateJump := x"03";
					when x"03" => 
						-- RESETA OS SINAIS DE ACOES DE MOVIMENTO
						if (jump <= 0) then -- SE CONTADOR DE PULO <= 0
							var_stateIntermediateJump := x"01"; 
						else
							var_stateIntermediateJump := x"04";
						end if;
					when x"04" => -- ESTADO DE PULO; 
						var_stateintermediateJump := x"03"; -- VOLTA PARA ESTADO GERAL
					when others => -- ESTADO GENERICO
						var_stateIntermediateJump := x"01"; -- VAI P/ ESTADO DE RESET
				END CASE;
			
				var_stateJump := var_stateintermediateJump;
			
				case var_stateJump is
					when x"01" => -- ESTADO DE RESET
						var_y := 21; -- VOLTA P/ POS Y INICIAL
						jump := 0; -- RESETA O CONTADOR DE PULO
						jumpResponse <= '0';

					when x"02" => -- ESTADO DE BRIEFING DE MOVIMENTO INICIAL
						jump := 300000; -- COLOCA O CONTADOR DE PULO PARA 300000
						jumpResponse <= '1'; -- ENVIA O SINAL PARA INDICAR QUE PULOU

					when x"03" => 
					
					when x"04" => -- ESTADO DE PULO (contador em [1 - 300.000])
						case jump is
							--DESCIDA
							when (8578)   => var_y := var_y + 1;
							when (17712)  => var_y := var_y + 1;
							when (27525)  => var_y := var_y + 1;
							when (38196)  => var_y := var_y + 1;
							when (50000)  => var_y := var_y + 1;
							when (63397)  => var_y := var_y + 1;
							when (79289)  => var_y := var_y + 1;
							when (100000) => var_y := var_y + 1;
							---SUBIDA
							when (300000 - 8578) => var_y := var_y - 1;
							when (300000 - 17712) => var_y := var_y - 1;
							when (300000 - 27525) => var_y := var_y - 1;
							when (300000 - 38196) => var_y := var_y - 1;
							when (300000 - 50000) => var_y := var_y - 1;
							when (300000 - 63397) => var_y := var_y - 1;
							when (300000 - 79289) => var_y := var_y - 1;
							when (300000 - 100000) => var_y := var_y - 1;
							when others => var_y := var_y;
						end case;
						jump := jump - 1; 
					when others => -- ESTADO GENERICO
						var_stateJump := x"01"; -- VAI P/ ESTADO DE RESET
				END CASE;
			END IF;
			--ATUALIZA OS SINAIS DE ACORDO COM AS VARIABLES
			sig_y <= to_UNsigned(var_y, 8);
			state_jump <= var_stateJump;
		END PROCESS;
		
		-- mAQUINA DE ESTADO DE MOVIMENTO HORIZONTAL
		-- tentar fazer com que o delay decresça no mesmo passo apesar de não estar sendo pressionado
		-- porém tornar a resposta de andar imediata após um tempo ou no caso de alternancia de direção
		PROCESS(clk, reset, signal_force_reset)
			VARIABLE var_stateMov : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"00"; -- ESTADO DA MAQ. DE ESTADO DE MOV.
			VARIABLE var_stateintermediateMov: STD_LOGIC_VECTOR(7 DOWNTO 0) := x"00";
			VARIABLE var_moveResponse: STD_LOGIC := '0';
			VARIABLE var_x: INTEGER := to_integer(sig_x(7 DOWNTO 0)); -- INDICADOR DE POS X
			VARIABLE var_dir: STD_LOGIC := sig_dir; -- INDICADOR DE DIRECAO
			VARIABLE var_moveDelay: INTEGER := 0; -- DELAY DE MOVIMENTO HORIZONTAL
			BEGIN
			IF (reset = '1' or signal_force_reset = '1') then
				var_stateMov := x"00";
			elsif (clk'event and clk = '1') then
				CASE var_stateMov IS
					when x"01" => -- ESTADO DE RESET
						var_stateintermediateMov := x"02"; -- VAI PARA ESTADO DE MOVIMENTO GERAL
					when x"02" => -- ESTADO DE MOVIMENTO GERAL
						if (var_moveDelay <= 0 and sig_dead = '0') then
							if (moveSignal = "01" ) then-- MOV PARA A ESQUERDA
								var_stateintermediateMov := x"FE";
							elsif (moveSignal = "10") then -- MOV PARA A DIREITA
								var_stateintermediateMov := x"FD";
							end if;
						end if;
					when x"FD" => -- ESTADO DE MOVIMENTO A DIREITA
						var_stateintermediateMov := x"02";
					when x"FE" => -- ESTADO DE MOVIMENTO A ESQUERDA
						var_stateintermediateMov := x"02";
					when others => -- ESTADO GENERICO
						var_stateintermediateMov := x"01"; -- VAI P/ ESTADO DE RESET
				END CASE;
				
				var_stateMov := var_stateintermediatemov;
				
				CASE var_stateMov IS
					when x"01" => -- ESTADO DE RESET
						var_x := 20; -- VOLTA P/ POS X INICIAL
					
					when x"02" => -- ESTADO DE MOVIMENTO GERAL
					
						if (var_moveDelay > 0) then
							var_moveDelay := var_moveDelay - 1;
							var_moveResponse := '1';
						else 
							var_moveResponse := '0';	
							if (moveSignal = "01" ) then-- MOV PARA A ESQUERDA
								var_moveDelay := 75000;
								var_dir := '1';
							elsif (moveSignal = "10") then -- MOV PARA A DIREITA
								var_moveDelay := 75000;
								var_dir := '0';
							end if;
						end if;
					when x"FD" => -- ESTADO DE MOVIMENTO A DIREITA
						if (var_x < 38) then -- SE ESTIVER NOS LIMITES DA TELA
							var_x := var_x + 1; -- MOVE 1 PIXEL PRA DIREITA
						end if;
						
					when x"FE" => -- ESTADO DE MOVIMENTO A ESQUERDA
						if (var_x > 2) then -- SE ESTIVER NOS LIMITES DA TELA
							var_x := var_x - 1; -- MOVE 1 PIXEL PRA ESQUERDA
						end if;
					when others =>
						var_stateMov := x"01"; -- VAI P/ ESTADO DE RESET
				END CASE;
			END IF;
			-- ATUALIZA OS SINAIS EXTERNOS DE ACORDO COM AS VARIAVEIS
			state_mov <= var_stateMov;
			sig_dir <= var_dir;
			moveResponse <= var_moveResponse;
			sig_x <= to_UNsigned(var_x, 8);
		END PROCESS;
		
		-- MAQUINA DE ESTADO DE CONTROLE
		PROCESS(clk, reset)
			-- VARIAVEIS DE CONTROLE
			VARIABLE var_stateControl: STD_LOGIC_VECTOR(7 DOWNTO 0) := x"00";
			VARIABLE var_stateControlIntermediario: STD_LOGIC_VECTOR(7 DOWNTO 0) := x"00";
			VARIABLE var_energia: INTEGER := 15;
			VARIABLE var_delayIsatacked: INTEGER;
			VARIABLE var_dead: STD_LOGIC; -- SINAL DE VIDA
			BEGIN
			if (reset = '1') then
				var_stateControl := x"00"; -- VAI PARA ESTADO DE RESET
			elsif (clk'event and '1' = clk) then
				case var_stateControl is
					when x"01" =>
						var_stateControlIntermediario := x"02"; -- MUDA PARA ESTADO DE BRIEFING PADRAO DE CONTROLE
					when x"02" =>
						if (energia <= 0) then
							var_stateControlIntermediario := x"FF"; -- MUDA PARA ESTADO DE MORTE
						elsif (var_delayIsatacked <= 0 and isAtacked = '1') then -- CASO ESTEJA SENDO ATACADO
							var_stateControlIntermediario := x"03"; -- MUDA PARA O ESTADO DE ATAQUE DE OPONENTE
						end if;
					when x"03" =>
						var_stateControlIntermediario := x"02"; -- RETORNA AO ESTADO DE BRIEFING INICIAL
					when x"FF" =>
					when others =>
						var_stateControlIntermediario := x"01"; -- VAI PARA ESTADO DE RESET
				end case;
				
				var_stateControl := var_stateControlIntermediario;
			
				case var_stateControl is
					when x"01" => -- ESTADO DE RESET
						var_energia := 15; -- Recupera toda a energia
						var_dead := '0'; -- Renasce
						var_delayIsatacked := 0;
						
					when x"02" => -- ESTADO DE BRIEFING PADRAO DE CONTROLE
						if (var_delayIsatacked > 0) then -- CASO O PERSONAGEM ESTEJA 'INVULNERAVEL'
							var_delayIsatacked := var_delayIsatacked - 1; -- DIMINUI O DELAY DE INVENCIBILIDADE
						end if;

					when x"03" => -- ESTADO DE ATAQUE DO OPONENTE
						var_energia := var_energia - 1; -- PERDE UMA UNIDADE DE ENERGIA
						var_delayIsatacked := 500000;
						
					when x"FF" => -- ESTADO DE MORTE
						var_dead := '1'; -- ENVIA SINAL DE MORTE

					when others => -- ESTADO DE GERAL DEBUG
						var_stateControl := x"01"; -- VAI PARA ESTADO DE RESET
				END CASE;
			END IF;
			-- ATUALIZA OS SIGNALS DE CONTROLE DE ACORDO COM AS VARIABLES
			state_control <= var_stateControl;
			energia <= to_UNsigned(var_energia, 8);
			sig_dead <= var_dead;
			-- delayattack <= to_unsigned(var_delayIsatacked, 8);
		END PROCESS;
		
		-- MAQUINA DE ESTADO DE ACAO
		-- E USADO O SIG DIR PARA IDENTIFICAR A DIRECAO DO ATAQUE
		PROCESS(clk, reset, signal_force_reset)
			-- VARIAVEIS DE ACAO (ATAQUE, OBTER ITEM)
			VARIABLE var_stateAct: STD_LOGIC_VECTOR(7 DOWNTO 0) := x"00";
			VARIABLE var_stateActIntermediario: STD_LOGIC_VECTOR(7 DOWNTO 0) := x"00";
			VARIABLE var_delayattack: integer;
			BEGIN
			if (reset = '1' and signal_force_reset = '1') then
				var_stateAct := x"00"; -- VAI PARA ESTADO DE RESET
			elsif (clk'event and '1' = clk) then
				case var_stateAct is
					when x"01" => -- ESTADO DE RESET
						var_stateActIntermediario := x"02";
					when x"02" => -- ESTADO GERAL
						if (isAtacking = '1' and var_delayattack <= 0) then
							var_stateActIntermediario := x"03";
						end if;
					when x"03" => -- ESTADO DE ATTACK
						var_stateActIntermediario := x"02";
					when others => -- ESTADO GERAL DE DEBUG
						var_stateActIntermediario := x"01"; -- VAI PARA ESTADO DE RESET
				END CASE;
				
				var_stateAct := var_stateActIntermediario;
				
				case var_stateAct is
					when x"01" => -- ESTADO DE RESET
						var_delayattack := 0;
					when x"02" => -- ESTADO GERAL
						if (var_delayattack > 0) then
							var_delayattack := var_delayattack - 1;
						end if;
					when x"03" => -- ESTADO DE ATTACK
						var_delayattack := 200000; 
					when others => -- ESTADO GERAL DE DEBUG
						var_stateAct := x"01"; -- VAI PARA ESTADO DE RESET
				END CASE;
			END IF;
			-- ATUALIZA OS SINAIS EXTERNOS DE ACORDO COM AS VARIAVEIS
			delayattack <= to_unsigned(var_delayattack, 8);
			state_action <= var_stateAct;
		END PROCESS;
		
		--ATUALIZA OS SINAIS DE SAIDA
		x <= sig_x;
		y <= sig_y;
		dead <= sig_dead;
		moveDirection <= sig_dir;
		sig_energia <= energia;
END player;