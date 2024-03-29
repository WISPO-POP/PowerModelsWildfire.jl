% Case to test adding data to matpower file
% tests refrence bus detection
% tests basic ac and hvdc modeling
% tests when gencost is present but not dclinecost
% quadratic objective function

function mpc = case3
mpc.version = '2';
mpc.baseMVA = 100.0;
mpc.bus = [
	1	 2	 110.0	 40.0	 0.0	 0.0	 1	    1.10000	   -0.00000	 240.0	 1	    1.10000	    0.90000;
	2	 2	 110.0	 40.0	 0.0	 0.0	 1	    0.92617	    7.25883	 240.0	 1	    1.10000	    0.90000;
	3	 2	 95.0	 50.0	 0.0	 0.0	 1	    0.90000	  -17.26710	 240.0	 2	    1.10000	    0.90000;
];
%column_names%  power_risk base_risk
mpc.bus_risk = [
    1.0 1.0;
    1.0 1.0;
    1.0 1.0;
];

mpc.gen = [
	1	 158.067	 28.79	 1000.0	 -1000.0	 1.1	 100.0	 1	 2000.0	 0.0;
	2	 160.006	-4.63	 1000.0	 -1000.0	 0.92617	 100.0	 1	 1500.0	 0.0;
	3	 0.0	 -4.843	 1000.0	 -1000.0	 0.9	 100.0	 1	 0.0	 0.0;
];
%column_names%  power_risk base_risk
mpc.gen_risk = [
    1.0 1.0;
    1.0 1.0;
    1.0 1.0;
];

mpc.gencost = [
	2	 0.0	 0.0	 3	   0.110000	   5.000000	   0.000000;
	2	 0.0	 0.0	 3	   0.085000	   1.200000	   0.000000;
	2	 0.0	 0.0	 3	   0.000000	   0.000000	   0.000000;
];

mpc.branch = [
	1	 3	 0.065	 0.62	 0.45	 9000.0	 0.0	 0.0	 0.0	 0.0	 1	 -30.0	 30.0;
	3	 2	 0.025	 0.75	 0.7	 50.0	 0.0	 0.0	 0.0	 0.0	 1	 -30.0	 30.0;
	1	 2	 0.042	 0.9	 0.3	 9000.0	 0.0	 0.0	 0.0	 0.0	 1	 -30.0	 30.0;
];
%column_names%  power_risk base_risk
mpc.branch_risk = [
    1.0 1.0;
    1.0 1.0;
    1.0 1.0;
];

