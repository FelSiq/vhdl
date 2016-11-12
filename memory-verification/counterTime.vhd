LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;

ENTITY counterTime IS
	PORT(
		clock		: 	IN STD_LOGIC;
		reset		:	IN STD_LOGIC;
		bitOut	:	OUT STD_LOGIC := '0'
		);
END counterTime;

ARCHITECTURE counter OF counterTime IS
	BEGIN
		PROCESS(reset, clock)
			VARIABLE number : NATURAL := 0;
			BEGIN
				IF reset = '1' THEN
					number := 0;
				ELSIF clock'event and clock = '1' THEN
					number := (number + 1) MOD 50000001;
					IF number = 50000000 THEN
						bitOut <= '1';
					ELSE
						bitOut <= '0';
					END IF;
				END IF;
		END PROCESS;
END counter;