LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY enemy1 IS
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
		signal_enable_global	: IN STD_LOGIC;
		signal_force_reset	: in STD_LOGIC
	);
END enemy1;

ARCHITECTURE enem_01 OF enemy1 IS
	-- SINAIS DE AUXILIO PARA O USO ENTRE PROCESS E PASSAGEM PARA MODULO EXTERNO
	SIGNAL energia 		: UNSIGNED(3 DOWNTO 0) := x"1"; -- ENERGIA VAI DE 0 A 15;
	SIGNAL sig_x			: UNSIGNED(7 DOWNTO 0); -- X
	SIGNAL sig_y			: UNSIGNED(7 DOWNTO 0); -- Y
	SIGNAL sig_dead		: STD_LOGIC := '0'; -- INICIALIZA VIVO (UFA!)
BEGIN
	-- OS INIMIGOS NAO PRECISAM SER MUITO INTELIGENTES. BASTA QUE ANDEM P/ ESQUERDA E DIREITA
	-- RECONHENDO OS LIMITES DE MOVIMENTO
		
	-- MAQUINA DE ESTADO DE MOVIMENTO
	PROCESS(clk, reset, signal_force_reset)
		-- VARIAVEIS DE MOVIMENTO
		VARIABLE var_stateMov : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"00"; -- ESTADO DA MAQ. DE ESTADO DE MOV.
		VARIABLE var_stateMovIntermediario : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"00"; -- ESTADO DA MAQ. DE ESTADO DE MOV.
		VARIABLE move_delay : INTEGER; -- DELAY DE MOVIMENTO DO INIMIGO;
		VARIABLE var_x : UNSIGNED(7 DOWNTO 0) := x_start;
		VARIABLE var_y : UNSIGNED(7 DOWNTO 0) := y_start; 
		VARIABLE var_dir : STD_LOGIC;  -- '1' LEFT/ '0' RIGHT
		
		BEGIN
		if (reset = '1' or signal_force_reset = '1') then
			var_stateMov := x"00"; -- FORÇA ESTADO DE RESET
		elsif (clk'event and '1' = clk) then
			CASE var_stateMov is
				when x"01" =>
					var_x := x_start;
					var_y := y_start;
					var_stateMovIntermediario := x"02"; -- VAI PARA ESTADO DE BRIEFING GERAL
				when x"02" =>
					if (move_delay <= 0 and sig_dead = '0') then
						var_stateMovIntermediario := x"03"; -- VAI PARA ESTADO DE MOVIMENTO DE ACORDO COM A DIRECAO
					end if;
				when x"03" =>
					if (var_dir = '1') then -- SE DIR LEFT
						var_stateMovIntermediario := x"AE";
					else -- SE NAO, DIR RIGHT
						var_stateMovIntermediario := x"AD";
					end if;
				when x"AE" => 
					var_stateMovIntermediario := x"02"; -- VOLTA PARA ESTADO GERAL DE MOV
				when x"AD" => 
					var_stateMovIntermediario := x"02"; -- VOLTA PARA ESTADO GERAL DE MOV
				WHEN OTHERS => 
					var_stateMovIntermediario := x"01"; -- VAI PARA ESTADO DE RESET
			END CASE;
			
			var_stateMov := var_stateMovIntermediario;
			
			case var_stateMov is
				when x"01" => -- ESTADO DE RESET
					var_x := x_start; -- RESETA X
					var_y := y_start; -- RESETA Y
					var_dir := '1'; -- DIR PRA ESQ
					move_delay := 0; -- RESET MOVDELAY
					
				when x"02" => -- ESTADO DE BRIEFING GERAL
					move_delay := move_delay - 1;
					
				when x"03" => -- ESTADO DE MOVIMENTO DE ACORDO COM A DIRECAO
					move_delay := 250000; -- ACRESCENTA DELAY PARA PROX MOVIMENTO
					
				when x"AE" => -- MOVIMENTO PARA A ESQUERDA
					if (var_x > 2) then
						var_x := var_x - 1;
					else
						var_x := var_x + 1;
						var_dir := '0';
					end if;
					
				when x"AD" => -- MOVIMENTO PARA A DIREITA
					if (var_x < 38) then
						var_x := var_x + 1;
					else
						var_x := var_x - 1;
						var_dir := '1';
					end if;
					
				when others => -- CASO GERAL DE DEBUG
					var_stateMov := x"01";
			END CASE;
		END IF;
		-- ATUALIZA OS SINAIS EXTERNOS DE ACORDO COM A VARIAVEIS
		state_mov <= var_stateMov;
		sig_x <= var_x;
		sig_y <= var_y;
		direction <= var_dir;
	END PROCESS;
	
	-- MAQUINA DE ESTADO DE CONTROLE
	PROCESS(clk, reset, signal_force_reset)
		-- VARIAVEIS DE CONTROLE
		-- LEMBRANDO QUE O INIMIGO NAO RETORNA AO MORRER
		VARIABLE var_stateCon 	: STD_LOGIC_VECTOR(7 DOWNTO 0) := x"00"; -- ESTADO DA MAQ. DE ESTADO DE CONTROLE.
		VARIABLE var_stateConIntermediario 	: STD_LOGIC_VECTOR(7 DOWNTO 0) := x"00"; -- ESTADO DA MAQ. DE ESTADO DE CONTROLE.
		VARIABLE var_energia 	: UNSIGNED(3 DOWNTO 0) := x"1"; -- ENERGIA DO INIMIGO;
		VARIABLE var_atackdelay : INTEGER; -- DELAY DE INVULNERABILIDADE
		VARIABLE var_dead 		: STD_LOGIC := '0';
		BEGIN
			if (reset = '1' or signal_force_reset = '1') then
				var_stateCon := x"00"; -- FORÇA ESTADO DE RESET
			elsif (clk'event and '1' = clk) then
				CASE var_stateCon IS
					when x"01" =>
						var_stateConIntermediario := x"02"; -- VAI PARA O ESTADO GERAL DE CONTROLE
					when x"02" =>
						if (var_energia > 0)then -- SE ESTIVER VIVO E COM ENERGIA
							var_stateConIntermediario := x"03"; -- VAI PARA ESTADO DE COMBATE
						else -- NESTE CASO, O INIMIGO TEM ENERGIA <=0 MAS AINDA ESTA 'VIVO'
							var_stateConIntermediario := x"FF"; -- VAI PARA ESTADO DE MORTE
						end if;
					when x"03" => 
						var_stateConIntermediario := x"02"; -- VOLTA PARA ESTADO DE CONTROLE GERAL
					when x"FF" => 
						var_stateConIntermediario := x"02"; -- VOLTA PARA ESTADO GERAL DE CONTROLE
					when others => 
						var_stateConIntermediario := x"01"; -- VOLTA PARA O ESTADO DE RESET
				END CASE;
				
				var_stateCon := var_stateConIntermediario;
				
				case var_stateCon is
					when x"01" => -- ESTADO DE RESET
						var_energia := energia_start; -- VOLTA A ENERGIA INICIAL
						var_atackdelay := 0; -- RETIRA INVULNERABILIDADE
						var_dead := '0'; -- RENASCE
					when x"02" => -- ESTADO GERAL DE CONTROLE
						if (var_atackdelay > 0) then
							var_atackdelay := var_atackdelay - 1; -- DIMINUI DELAY DE INVULNERABILIDADE
						end if;
					when x"03" => -- ESTADO DE COMBATE
						var_dead := '0';
						if (isAtacked = '1' and var_atackdelay <= 0) then -- SE FOR ATACADO E PUDER SER ATACADO
							var_atackdelay := 200000; -- ADICIONA DELAY PARA SER ATACADO NOVAMENTE
							var_energia := var_energia - 1; -- PERDE UMA UNIDADE DE ENERGIA
						end if;
					when x"FF" => -- ESTADO DE MORTE
						var_dead := '1';
					when others => -- ESTADO GERAL DE DEBUG
						var_stateCon := x"01";
				END CASE;
			END IF;
			-- ATUALIZA SINAIS EXTERNOS DE ACORDO COM AS VARIAVEIS
			state_control <= var_stateCon;
			energia <= var_energia;
			sig_dead <= var_dead;
	END PROCESS;
	
	--ATUALIZAR SINAIS EXTERNOS VIA SINAIS INTERNOS
	dead <= sig_dead;
	x <= sig_x;
	y <= sig_y;
END enem_01;