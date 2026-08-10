function [results, imagesOut] = parameterSelectorRunSweep( ...
        im, gt, roiMask, cisterna, erMask, erFenestrations, cellBoundary, imBackground, ...
        enhanceCurrentParams, skeletonCurrentParams, combos, tolerance, fwhmTarget, code, ...
        progressFcn, keepImages)
%PARAMETERSELECTORRUNSWEEP  Run every combo in `combos`, return a ranked
%results table.
%
%   results = parameterSelectorRunSweep(im, gt, roiMask, cisterna, ...
%       erMask, erFenestrations, cellBoundary, imBackground, ...
%       enhanceCurrentParams, skeletonCurrentParams, combos, ...
%       tolerance, fwhmTarget, code)
%   results = parameterSelectorRunSweep(..., progressFcn)
%   [results, imagesOut] = parameterSelectorRunSweep(..., progressFcn, keepImages)
%
% ARGUMENTS
%   enhanceCurrentParams, skeletonCurrentParams – the live current params
%           structs for each step (e.g. app.parameters.er.network.enhance/
%           .skeleton) — used only for step-level fields, see
%           parameterSelectorBuildFlatParams.
%   combos       – output of parameterSelectorExpandCombos.
%   tolerance    – ROC match tolerance in pixels (analyzerRocAnalysis).
%   fwhmTarget   – app.parameterDefaults.process.main.resample.fwhmTarget;
%                  sets pEnhance.fwhmTarget (guided-filter merge) and
%                  pSkeleton.minAreaPixels = fwhmTarget*2, matching the live
%                  app (AnalyzER_app_extracted.m:13493,13536).
%   code         – filename string stamped into every results row.
%   progressFcn  – optional @(iCombo, nCombos) callback for a UI progress bar.
%   keepImages   – optional logical (default false). When true, also
%                  returns per-combo images (memory-heavy for large sweeps;
%                  the UI should normally re-run a single combo on demand
%                  instead of keeping every combo's images in memory).
%
% RETURNS
%   results   – table, one row per combo: combo (index into `combos`),
%               enhanceMethod, skeletonMethod, then the ROC stats columns
%               from analyzerRocAnalysis (TP/FP/.../F1/Fbeta2/MCC/...).
%   imagesOut – cell array of per-combo image structs (parameterSelectorRunCombo
%               output), only populated when keepImages is true; otherwise {}.

    if nargin < 15 || isempty(progressFcn)
        progressFcn = [];
    end
    if nargin < 16 || isempty(keepImages)
        keepImages = false;
    end

    nCombos = numel(combos);
    rows = cell(nCombos, 1);
    imagesOut = {};
    if keepImages
        imagesOut = cell(nCombos, 1);
    end

    for k = 1:nCombos
        if ~isempty(progressFcn)
            progressFcn(k, nCombos);
        end
        c = combos(k);

        pEnhance = parameterSelectorBuildFlatParams(enhanceCurrentParams, c.enhanceMethod, c.enhanceValues);
        pEnhance.legacyFlag = 0;
        pEnhance.fwhmTarget = fwhmTarget;

        pSkeleton = parameterSelectorBuildFlatParams(skeletonCurrentParams, c.skeletonMethod, c.skeletonValues);
        pSkeleton.minAreaPixels = fwhmTarget * 2;

        [statsRow, images] = parameterSelectorRunCombo(im, gt, roiMask, cisterna, ...
            erMask, erFenestrations, cellBoundary, imBackground, pEnhance, pSkeleton, tolerance, code);

        statsRow.combo          = k;
        statsRow.enhanceMethod  = string(c.enhanceMethod);
        statsRow.skeletonMethod = string(c.skeletonMethod);
        rows{k} = statsRow;

        if keepImages
            imagesOut{k} = images;
        end
    end

    results = vertcat(rows{:});
    results = movevars(results, {'combo', 'enhanceMethod', 'skeletonMethod'}, 'Before', 1);
end
