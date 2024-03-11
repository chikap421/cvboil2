function bubblemetrics()
    clc; close all; clear;
    segmentationDir = '/Users/chikamaduabuchi/Documents/paul/segmentation1';
    groundTruthDir = '/Users/chikamaduabuchi/Documents/paul/groundtruth';
    [metricsArray, imageFileNames] = calculateAllMetrics(segmentationDir, groundTruthDir);
    % plotMetricsArray(metricsArray, imageFileNames);
    T = calculateAndDisplayErrors(metricsArray, imageFileNames); % Capture T
    plotErrorAnalysis(T, {'Dry_Area', 'Contact_Line'}); % Now T is passed here
end


function [metricsArray, imageFileNames] = calculateAllMetrics(segmentationDir, groundTruthDir)
    segFiles = dir(fullfile(segmentationDir, '*.tif'));
    numFiles = length(segFiles);
    metricsArray = repmat(struct('segmented', [], 'groundTruth', []), numFiles, 1);
    imageFileNames = strings(numFiles, 1);

    for i = 1:numFiles
        imageFileNames(i) = segFiles(i).name; 
        segImagePath = fullfile(segmentationDir, segFiles(i).name);
        gtImagePath = fullfile(groundTruthDir, segFiles(i).name);

        segBinaryMask = imbinarize(imread(segImagePath));
        gtBinaryMask = imbinarize(imread(gtImagePath));

        segMetrics = calculateDryAreaAndContactLine(segBinaryMask);
        gtMetrics = calculateDryAreaAndContactLine(gtBinaryMask);

        metricsArray(i).segmented = segMetrics;
        metricsArray(i).groundTruth = gtMetrics;
    end
end

function metrics = calculateDryAreaAndContactLine(binaryMask)
    totalPixels = numel(binaryMask);
    wetPixels = sum(binaryMask == 0, 'all');
    dryAreaFraction = 1 - (wetPixels / totalPixels);

    invertedBinaryMask = ~binaryMask;
    dist = bwdist(invertedBinaryMask);
    contactLineLength = sum(dist == 1, 'all');
    contactLineDensity = contactLineLength / totalPixels;

    metrics = struct('dry_area_fraction', dryAreaFraction, 'contact_line_density', contactLineDensity);
end


function plotMetricsArray(metricsArray, imageFileNames)
    numMetrics = 2;
    numFiles = length(metricsArray);
    metricLabels = {'Dry Area Fraction', 'Contact Line Density'};
    metricsData = zeros(numFiles, numMetrics, 2);
    imageNames = strings(numFiles, 1);

    for i = 1:numFiles
        imageNames(i) = erase(erase(imageFileNames(i), "Img"), ".tif");
        metricsData(i, 1, 1) = metricsArray(i).segmented.dry_area_fraction;
        metricsData(i, 1, 2) = metricsArray(i).groundTruth.dry_area_fraction;
        metricsData(i, 2, 1) = metricsArray(i).segmented.contact_line_density;
        metricsData(i, 2, 2) = metricsArray(i).groundTruth.contact_line_density;
    end

    figure;
    for i = 1:numMetrics
        subplot(numMetrics, 1, i);
        hold on;
        box on;
        set(gca, 'LineWidth', 2);
        bar(squeeze(metricsData(:, i, :)), 'grouped');
        set(gca, 'xticklabel', imageNames, 'XTick', 1:numFiles);
        xlabel('Image Name');
        ylabel(metricLabels{i});
        if i == 1
            legend('Segmented', 'Ground Truth', 'Location', 'best');
        end
        set(gca, 'FontSize', 14, 'FontWeight', 'bold');
        grid on;
        set(gca, 'GridLineStyle', '-', 'GridColor', 'k', 'GridAlpha', 0.3); 
        set(gca, 'MinorGridLineStyle', ':', 'MinorGridColor', 'k', 'MinorGridAlpha', 0.05);
        ax = gca;
        ax.XAxis.MinorTick = 'on';
        ax.YAxis.MinorTick = 'on';
        ax.XMinorGrid = 'on';
        ax.YMinorGrid = 'on';
        hold off;
    end
end

function T = calculateAndDisplayErrors(metricsArray, imageFileNames)
    numFiles = length(metricsArray);
    
    dryAreaError = zeros(numFiles, 1);
    dryAreaPercError = zeros(numFiles, 1);
    contactLineError = zeros(numFiles, 1);
    contactLinePercError = zeros(numFiles, 1);
    
    for i = 1:numFiles
        dryAreaError(i) = metricsArray(i).segmented.dry_area_fraction - metricsArray(i).groundTruth.dry_area_fraction;
        dryAreaPercError(i) = (dryAreaError(i) / metricsArray(i).groundTruth.dry_area_fraction) * 100;
        
        contactLineError(i) = metricsArray(i).segmented.contact_line_density - metricsArray(i).groundTruth.contact_line_density;
        contactLinePercError(i) = (contactLineError(i) / metricsArray(i).groundTruth.contact_line_density) * 100;
    end
    
    processedImageNames = erase(erase(imageFileNames, "Img"), ".tif");
    
    T = table(processedImageNames, dryAreaError, dryAreaPercError, contactLineError, contactLinePercError, ...
        'VariableNames', {'Image_Name', 'Dry_Area_Error', 'Dry_Area_Perc_Error', 'Contact_Line_Error', 'Contact_Line_Perc_Error'});
    
    writetable(T, 'error_analysis.xlsx')

    disp(T);
end

function plotErrorAnalysis(T, metricNames)
    numMetrics = numel(metricNames);
    absoluteErrorColor = [0, 0, 1]; % Blue color for absolute error
    percentageErrorColor = [1, 0, 0]; % Red color for percentage error
    figure('Name', 'Error Analysis', 'NumberTitle', 'off');
    
    for i = 1:numMetrics
        metricLabel = metricNames{i};
        absErrorName = [metricLabel, '_Error'];
        percErrorName = [metricLabel, '_Perc_Error'];
        
        subplot(numMetrics, 1, i);
        yyaxis left;
        scatter(1:height(T), T.(absErrorName), 'filled', 'MarkerFaceColor', absoluteErrorColor, 'MarkerEdgeColor', absoluteErrorColor);
        if strcmp(metricLabel, 'Contact_Line') % Check if the current metric is Contact_Line
            ylabel('Absolute Error (px/px^2)', 'FontWeight', 'bold');
        else
            ylabel('Absolute Error', 'FontWeight', 'bold');
        end
        set(gca, 'YColor', absoluteErrorColor, 'LineWidth', 2, 'FontWeight', 'bold', 'FontSize', 12);
        
        yyaxis right;
        plot(1:height(T), T.(percErrorName), '-o', 'Color', percentageErrorColor, 'MarkerFaceColor', percentageErrorColor);
        ylabel('Percentage Error (%)', 'FontWeight', 'bold');
        set(gca, 'YColor', percentageErrorColor, 'LineWidth', 2, 'FontWeight', 'bold', 'FontSize', 12);
        
        % Customize plot
        title([strrep(metricLabel, '_', ' '), ' Error Analysis'], 'FontWeight', 'bold', 'FontSize', 14);
        xlabel('Image Name', 'FontWeight', 'bold');
        xticks(1:height(T));
        xticklabels(T.Image_Name);
        xtickangle(45);
        grid on;
        set(gca, 'FontWeight', 'bold', 'FontSize', 12);
        box on;
        
        if i == 1 % Legend for the first subplot only
            legend({'Absolute Error', 'Percentage Error'}, 'Location', 'best', 'FontWeight', 'bold');
        end
    end
end
