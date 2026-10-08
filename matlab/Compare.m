%-- Log from MATLAB Model.

Input_Vec = round(matlabInput.Data(1:800).*2^13);

file_Input_Signal1 = fopen('C:\Users\Hasan\My_Projects\DSP\Trumpf_Project\matlab\input_Vec.txt','w');

for i = 1:length(Input_Vec)
    fprintf(file_Input_Signal1,'%d\r\n',Input_Vec(i));
end;

fclose(file_Input_Signal1);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Output_Vec = round(matlabOutput.Data(1:800).*2^13);

file_Input_Signal2 = fopen('C:\Users\Hasan\My_Projects\DSP\Trumpf_Project\matlab\output_Vec_Matlab.txt','w');

for i = 1:length(Output_Vec)
    fprintf(file_Input_Signal2,'%d\r\n',Output_Vec(i));
end;

fclose(file_Input_Signal2);

%%

%-- Log from MATLAB Model and VHDL simulation.

file_Output_Signal_1 = fopen('C:\Users\Hasan\My_Projects\DSP\Trumpf_Project\matlab\output_Vec_Matlab.txt');
Output_Vec_Sig = fscanf(file_Output_Signal_1 , '%d');
fclose(file_Output_Signal_1);

file_Output_Signal_2 = fopen('C:\Users\Hasan\My_Projects\DSP\Trumpf_Project\matlab\Output_Vec_VHDL.txt');
Output_Vec_Sig_HDL = fscanf(file_Output_Signal_2 , '%d');
fclose(file_Output_Signal_2);



plot(Output_Vec_Sig(1:800)./2^13)
hold
plot(Output_Vec_Sig_HDL(1:800)./2^13, 'ro')
legend('MATLAB - Fixed-Point','VHDL - Fixed-Point')