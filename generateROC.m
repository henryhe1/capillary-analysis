function [aroc, TPF, FPF] = generateROC(fov, area, idWithTruthList, FOVdir)

    inFocusMap = zeros(520, 696);
    noFocusMap = inFocusMap;
    % Get list of all 442 vessel geometry .mat files from the Processed
    % folder
    
    values = [];
    for i = 1:size(fov, 1)
    
        values = [values; nanmean(fov{i, 2}, 2)];

    end
    
    matList = dir([FOVdir '/VesselGeometry/*.mat']);
    counter = 1;
    for i = 1: length(matList)
        if ~isempty(strfind(matList(i).name, '442'))
            load([FOVdir '/VesselGeometry/' matList(i).name]);
            ycoords = Capillary2nd.Coordinates(2) + (1:Capillary2nd.y2(end));
            tempArea = area;
            indices = area == idWithTruthList(counter);
            tempArea(ycoords, :) = 1;
            
            % In focus capillaries
            if isempty(strfind(matList(i).name, 'anif')) && isempty(strfind(matList(i).name, 'agmf'))
                inFocusMap(indices & tempArea == 1) = 1;
              
            else
                noFocusMap(indices & tempArea == 1  & ~inFocusMap) = 1;
            end
            counter = counter + 1;
        end
    end
    
    nThresholds = 20;
    TPF = zeros(nThresholds, 1);
    FPF = zeros(nThresholds, 1);
    
    % Loop through all the capillary ids and create a mask that represents
    % the area that is not covered by any of the detected capillaries
    tempAreaMask = area ~= idWithTruthList(1);
    for i = 2:length(idWithTruthList)
        tempAreaMask = tempAreaMask & area ~= idWithTruthList(i);
    end
    inFocusMap(tempAreaMask) = 22;
    
    % Get histogram info
    [hist, edges] = generateHistogram(fov, true);
    cutoff = findMostValuesHist(hist, edges)
    
    thresholdRange = [linspace(0, cutoff, nThresholds) max(values)];
    for i = 1:length(thresholdRange)

        threshmap = threshMap(fov, area, thresholdRange(i), false);
        

        TPF(i) = sum(inFocusMap(threshmap == 1) == 1)/sum(inFocusMap(:) == 1);
        FPF(i) = sum(noFocusMap(threshmap == 1) == 1)/sum(noFocusMap(:) == 1);
    end

    %plot(0:0.1:1, 0:0.1:1);
    hold on;
    plot(FPF, TPF);
    %scatter(FPF, TPF);
       

    aroc = -trapz(FPF, TPF);
   
end

%[aroc, TPF, FPF] = generateROC(fov, area, [1100 1100 2100 600 4100 3100], 'C:\Users\Edward\Documents\Files\DUROP\DATA-2\Processed\X20-FOV3-B\')
%[aroc, TPF, FPF] = generateROC(fov, area, [1100 1100 2100 600 4100 3100], '/Volumes/DATA-2/Processed/20150619/X20-FOV3-B')