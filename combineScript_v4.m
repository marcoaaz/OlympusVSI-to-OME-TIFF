clear
clc
%Author: Marco Acevedo Z.
%It is recommended that the MaxHeapSize of the Java Virtual Machine (JDF
%v17 for Windows 64-bit; not the JRE) be permanently adjusted before
%using this script to have image pyramids of higher fidelity. 

archCPU = computer('arch');
if strcmp(archCPU, 'win64')
    disp('Proceed with each script section')
else
    disp('Due to your CPU architecture (32-bit), your maximum RAM available is 2GB.')
end

%Root folder
%Dependencies
bfFolder = 'C:\Users\Acer\bftools'; %Bioformat command-line folder
%https://docs.openmicroscopy.org/bio-formats/5.8.2/users/comlinetools/index.html

marcoFolder = 'D:\Disco_Nitro5\scripts_Marco\updated MatLab scripts';
addpath(marcoFolder)
addpath('C:\Users\Acer\Desktop\fullFile test')

%User input (edit accordingly)
workingDir = 'C:\Users\Acer\Desktop\fullFile test';
cd(workingDir)
unfoldDir = fullfile(workingDir, 'scripted');
destDir = fullfile(workingDir, 'scripted_sel');

sectionName = 'KB-63'; %if not = to fileName (usually the case)
str1 = fullfile(workingDir, 'Image_90.vsi');

%Script (default)
str2 = fullfile(workingDir, 'xml.txt');
str3 = fullfile(unfoldDir, 'output_z%%s.tiff');
str4 = fullfile(unfoldDir, 'naming.pattern');
str5 = fullfile(destDir, 'naming.pattern'); %wild card pattern
str6 = fullfile(workingDir, strcat(sectionName, '.ome.tiff'));
str7 = fullfile(workingDir, strcat(sectionName, '_sel.ome.tiff'));

%% Obtain metadata (Olympus *.vsi) 

delete(str2) 
command = ['cd "' bfFolder '"'];
command1 = ['showinf -no-upgrade -omexml -nopix -omexml-only "' str1 '" >> "' str2 '"'];

%showinf -no-upgrade -nopix -omexml-only test.ome.tiff >> "showinf-output.txt"
[status1, cmdout1] = system(strcat(command, ' & ', command1));
if status1 == 1
    disp(cmdout1)
end

S = fileread(str2);
S = regexprep(S, 'µm', 'micron');
new_filename = 'xml_reformated.txt';
fid = fopen(new_filename, 'w');
fwrite(fid, S); %save
fclose(fid);
outStruct = xml2struct(new_filename);

%Interpret metadata
%metadata of entire acquisition (same order as all data)
temp_struct = outStruct.OME.Instrument.Objective;
n_configurations = length(temp_struct);

temp_objectiveMeta = cell(n_configurations, 1);
for i = 1:n_configurations
    temp_objectiveMeta{i} = struct2table(temp_struct{1, i}.Attributes,'AsArray', true);     
end
temp_objectiveMeta2 = vertcat(temp_objectiveMeta{:});
col_names = temp_objectiveMeta2.Properties.VariableNames;
objectiveMeta = convertvars(temp_objectiveMeta2, col_names, 'string');

%Metadata of all images
n_files = length(outStruct.OME.Image);
temp_name = strings(n_files, 1);
temp_basicMetadata = cell(n_files, 1);
temp_exposure = strings(n_files, 1);
temp_gain = strings(n_files, 1);
for i = 1:n_files
    temp_name(i) = outStruct.OME.Image{1, i}.Attributes.Name;    
    temp_basicMetadata{i, 1} = struct2table(outStruct.OME.Image{1, i}.Pixels.Attributes,'AsArray', true);
    try        
        temp_exposure(i) = outStruct.OME.Image{1, i}.Pixels.Plane.Attributes.ExposureTime; %s
        temp_gain(i) = outStruct.OME.Image{1, i}.Pixels.Channel.DetectorSettings.Attributes.Gain;           
    catch        
        temp_exposure(i) = '';
        temp_gain(i) = '';    
    end
end
basicMeta = temp_basicMetadata{1, 1};
for ii = 2:n_files
    basicMeta = tblvertcat(basicMeta, temp_basicMetadata{ii, 1});
end

pause(0.1)
beep %continue after the sound

%% Translate image pyramid (run only once, ~20 min)
%https://docs.openmicroscopy.org/bio-formats/5.8.2/users/comlinetools/conversion.html

mkdir(unfoldDir)

command2 = ['bfconvert "' str1 '" "' str3 '" -padded'];
%bfconvert "C:\Users\Acer\Desktop\fullFile test\Image_90.vsi" "C:\Users\Acer\Desktop\fullFile test\test_serial naming2\output_z%%s.tiff" -padded

%Unfolding pyramid
[status2, cmdout2] = system(strcat(command, ' & ', command2));
if status2 == 1
    disp(cmdout2)
end

%% Gather relevant information

% # of pyramid levels (Olympus format): 
% %acquisition in highest resolution (not: label, overview, or macro images)
listing = dir(unfoldDir);
listing1 = struct2table(listing);
idx1 = endsWith(listing1.name, '.tiff', 'IgnoreCase', true);
idx2 = endsWith(listing1.name, 'ome.tiff', 'IgnoreCase', true);
idx3 = idx1 & ~idx2;
listing2 = listing1(idx3, :);
listing3 = sortrows(listing2, 'bytes', 'descend');

bytesValue = listing3.bytes;
[u_levels, ~, ic] = unique(bytesValue); %'stable'
[u_count, ~] = histcounts(bytesValue, [u_levels; u_levels(end)+1]);

mode_temp = mode(u_count(u_count ~= 1)); %# of interesting layers
idx_last = find(u_count == mode_temp, 1, 'last'); %order (Olympus format)
idx_first = find(listing2.bytes == u_levels(idx_last));
n_levels_oly = idx_first(2) - idx_first(1); %# of levels (Olympus format)

fprintf(['The input pyramid has:\n',...
    'acquisition layers= %d\n',...
    'pyramid levels= %d\n'], mode_temp, n_levels_oly)

%Informative tables
temp_index = [1:n_files]';
fileNames = listing2.name;
temp_date = listing2.date;
temp_bytes = listing2.bytes;
allMetadata = addvars(basicMeta, temp_index, fileNames, temp_date, temp_bytes, ...
    temp_name, temp_exposure, temp_gain, ...
    'NewVariableNames', {'Number', 'fileName', 'Date', 'Bytes', ...
    'Name', 'Exposure', 'Gain'}, 'Before', 1);

%Reference table
ref_table = allMetadata(:, {'fileName', 'Name', 'Bytes'});
temp_header = ref_table.Properties.VariableNames;
temp_header{3} = 'Megabytes';
ref_table.Properties.VariableNames = temp_header;
ref_table.Megabytes = ref_table.Megabytes/(1024^2); %Megabytes

%get acquisition series
ref_table1 = ref_table(idx_first, :);
ref_table2 = addvars(ref_table1, string([1:mode_temp]'), ...
    'NewVariableNames', {'Index'}, 'Before', 1);
disp(ref_table2)

%get cohort (pyramid levels)
from = idx_first(1); 
to = idx_first(2)-1;
ref_sizes = ref_table(from:to, :);
ref_size_list = ref_sizes.Megabytes;

%sanity check
str_position = ref_table2.fileName;
cell_position = string(regexp(str_position, '\d*', 'match'));
num_position = str2double(cell_position);
n_levels_oly_check = num_position(2) - num_position(1);
if n_levels_oly_check == n_levels_oly
    writetable(objectiveMeta, 'metadata.xlsx', 'Sheet', 'objectives');
    writetable(allMetadata, 'metadata.xlsx', 'Sheet', 'metadata');
    writetable(ref_table2, 'metadata.xlsx', 'Sheet', 'reference');
    writetable(ref_sizes, 'metadata.xlsx', 'Sheet', 'sizes');

    disp('The information was saved.')
else
    disp('Some images might be missing in the "script" folder')
end

%% GUI

pyramidMenu_v1(ref_table2, ref_size_list);

%% Producing pyramidal images (multipol brightfield for Petrography) 
%https://forum.image.sc/t/ome-tif-multi-channel-tiled-pyramid-from-individual-large-tiff-raw-files/23690/2
%https://docs.openmicroscopy.org/bio-formats/6.0.0/formats/pattern-file.html

fileNames = allMetadata.fileName; %retrieved from metadata.xlsx
idx_sel1 = idx_first + sel_level; %option 1
idx_sel2 = idx_sel1(sel_layer); %option 2

one_cond = sum(sel_layer == 1);
zero_cond = sum(sel_layer == 0);
if (one_cond == 0) && (zero_cond > 0)

    disp('Please, return to the GUI and select at least 1 layer.')
elseif (one_cond > 0) && (zero_cond == 0)

    %Option 1: sequential naming
    str_first = fileNames(idx_sel1(1));
    str_last = fileNames(idx_sel1(end));
    
    expression = '\d*';
    num_first = string(regexp(str_first, expression, 'match'));
    num_last = string(regexp(str_last, expression, 'match'));
    namingPattern = strcat('output_z<', num_first, '-', num_last, ...
        ':', num2str(n_levels_oly), '>.tiff');
    
    fid = fopen(str4, 'w');
    fwrite(fid, namingPattern);
    fclose(fid);
    
    %Pyramiding (as z-stack)
    %bfconvert -pyramid-resolutions 5 -pyramid-scale 2 -noflat "C:\Users\Acer\Desktop\fullFile test\test_serial naming2\naming.pattern" "C:\Users\Acer\Desktop\fullFile test\test_serial naming2\image2.ome.tiff"
    command3 = ['bfconvert -pyramid-resolutions 5 -pyramid-scale 2 -noflat -tilex 512 -tiley 512 -overwrite "' str4 '" "' str6 '"'];
    [status3, cmdout3] = system([command, ' & ', command3]);
    if status3 == 1
        disp(cmdout3)
    end
    
    %Options to play with:
    % BF_MAX_MEM=24g bfconvert
    % -tilex 512 -tiley 512 
    % -crop 0,0,2048,2048
    % -overwrite -compression LZW (or JPEG; JPEG-2000; depends on client decoding)
    
    %drafts: 'bfconvert -pyramid-resolutions 5 -pyramid-scale 2 -noflat -tilex 512 -tiley 512 -crop 0,0,512,512 -overwrite "' str4 '" "' str6 '"' 
    % command3 = ['bfconvert -pyramid-resolutions 5 -pyramid-scale 2 -noflat "' str4 '" "' str6 '"'];
    
elseif (one_cond > 0) && (zero_cond > 0)
    % Option 2: interactive (from GUI) and generate new folders
    mkdir(destDir)

    %get selected series
    n_images_mov = sum(sel_layer);
    ref_table_sel = ref_table(idx_sel2, :);
    ref_table_sel2 = addvars(ref_table_sel, string([1:n_images_mov]'), ...
        'NewVariableNames', {'Index'}, 'Before', 1);
    disp(ref_table_sel2)
    
    fileNames_sel = ref_table_sel2.fileName;
    % fileNames_sel2 = fullfile(destDir, fileNames_sel); %to
    fileNames_sel3 = fullfile(unfoldDir, fileNames_sel); %from
    for j = 1:n_images_mov
        copyfile(fileNames_sel3{j}, destDir) %incl. mkdir()
    end
    
    namingPattern = 'output_z.*.tiff';
    
    fid = fopen(str5, 'w');
    fwrite(fid, namingPattern);
    fclose(fid);
    
    %Pyramiding (as time-series due to naming gaps)
    command4 = ['bfconvert -pyramid-resolutions 5 -pyramid-scale 2 -noflat -tilex 512 -tiley 512 -overwrite "' str5 '" "' str7 '"'];
    [status4, cmdout4] = system([command, ' & ', command4]);
    if status4 == 1
        disp(cmdout4)
    end
end

disp('Done. In case you rerun the code, rename your files to not overwrite them.')
