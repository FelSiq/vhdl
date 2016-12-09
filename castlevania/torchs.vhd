LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY torchs IS
	PORT(
		--	SINAIS DE ESTADO
		state		: OUT STD_LOGIC_VECTOR(7 downto 0);
		-- SINAIS DE CARACTERISTICA
		broken	: OUT STD_LOGIC;
		atacked	: IN STD_LOGIC;
		x			: IN UNSIGNED(7 DOWNTO 0);
		y			: IN UNSIGNED(7 DOWNTO 0);
		-- SINAIS DE CONTROLE
		clk	:	IN STD_LOGIC;
		reset	:	IN STD_LOGIC;
		signal_enable_global : IN STD_LOGIC
	);
END torchs;
	
ARCHITECTURE torch OF torchs IS
BEGIN
	-- MAQUINA DE ESTADO UNICA
	PROCESS(clk, reset)
		--VARIAVEIS DO PROCESS
		VARIABLE var_state: STD_LOGIC_VECTOR(7 downto 0) := x"00";
		VARIABLE var_broken: STD_LOGIC := '0';
		BEGIN
			if (reset ='1') then
				var_state := x"00";
			elsif (clk'event and clk = '1') then
				case var_state is
					when x"01" => -- ESTADO DE RESET
						var_broken := '0'; -- RESETA SE ESTIVER QUEBRADA
						var_state := x"02"; -- VAI PARA ESTADO GERAL
					when x"02" => -- ESTADO GERAL
						if (atacked = '0' or var_broken = '1') then 
							var_state := x"02"; -- LOOP
						end if;
						if (atacked = '1' and var_broken = '0') then
							var_state := x"03"; -- ESTADO DE ATAQUE
						end if;
					when x"03" => -- ESTADO DE ATAQUE
						var_broken := '1'; -- TORNA-SE QUEBRADA
						var_state := x"02"; -- ESTADO GERAL
					when others => -- ESTADO DE DEBUG
						var_state := x"01"; -- VAI PARA ESTADO DE RESET
				END CASE;
			END IF;
			-- ATUALIZAR OS SINAIS EXTERNOS DE ACORDO COM AS VARIAVEIS
			state <= var_state;
			broken <= var_broken;
	END PROCESS;
END torch;