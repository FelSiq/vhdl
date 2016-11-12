LIBRARY ieee;
USE ieee.std_logic_1164.all;
LIBRARY altera_mf;
USE altera_mf.all;

ENTITY box IS
	port( 
		hexAdress, hex3, hex2, hex1, hex0	:	OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
		clock											: 	IN STD_LOGIC := '1';
		reset											:	IN STD_LOGIC);
END box;

ARCHITECTURE decoder OF box IS
	-- SIGNALS
	SIGNAL switch3, switch2, switch1, switch0  	:	STD_LOGIC_VECTOR(3 DOWNTO 0);
	SiGNAL adress : STD_LOGIC_VECTOR(3 DOWNTO 0) := "1010";
	SIGNAL q													:	STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL bitOut											:	STD_LOGIC := '0';
	
	-- COMPONENTE TIMET
	COMPONENT counterTime IS
		PORT(
			clock		: 	IN STD_LOGIC;
			reset		:	IN STD_LOGIC;
			bitOut	:	OUT STD_LOGIC
			);
	END COMPONENT;
	
	-- COMPONENTE CONTADOR
	COMPONENT counter4b IS
		PORT(
			clock	: 	IN STD_LOGIC;
			reset	:	IN STD_LOGIC;
			bits	:	OUT STD_LOGIC_VECTOR(3 DOWNTO 0));
	END COMPONENT;

	-- COMPONENTE DISPLAY 7 SEGMENTOS
	COMPONENT seg IS
		PORT(reset: IN STD_LOGIC;
			num: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
			hex: OUT STD_LOGIC_VECTOR(6 DOWNTO 0));
	END COMPONENT;
	
	-- COMPONENTE MEMORIA "CORTANA"
	COMPONENT cortana IS
		PORT(address		: IN STD_LOGIC_VECTOR (3 DOWNTO 0);
			  clock		: IN STD_LOGIC  := '1';
			  data		: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
			  wren		: IN STD_LOGIC ;
			  q		: OUT STD_LOGIC_VECTOR (15 DOWNTO 0));
	END COMPONENT;

		BEGIN			
			timeT: counterTime port map (clock, reset, bitOut);
			
			counts: counter4b port map (bitOut, reset, adress);	
						
			mem: cortana port map (adress, bitOut, (OTHERS => '0'), '0', q);
					
			switch0(3 DOWNTO 0) <= q(3 DOWNTO 0);
			switch1(3 DOWNTO 0) <= q(7 DOWNTO 4);
			switch2(3 DOWNTO 0) <= q(11 DOWNTO 8);
			switch3(3 DOWNTO 0) <= q(15 DOWNTO 12);
			
			dec0: seg port map ('0', switch0, hex0);
			dec1: seg port map ('0', switch1, hex1);
			dec2: seg port map ('0', switch2, hex2);
			dec3: seg port map ('0', switch3, hex3);
			
			--decAdress: seg port map ('0', adress, hexAdress);
END decoder;