function [statsRow, images] = parameterSelectorRunCombo( ...
        im, gt, roiMask, cisterna, erMask, erFenestrations, cellBoundary, imBackground, ...
        pEnhance, pSkeleton, tolerance, code)
%PARAMETERSELECTORRUNCOMBO  Run one enhance+skeleton parameter combo and
%score it against ground truth.
%
%   [statsRow, images] = parameterSelectorRunCombo( ...
%       im, gt, roiMask, cisterna, erMask, erFenestrations, cellBoundary, imBackground, ...
%       pEnhance, pSkeleton, tolerance, code)
%
% Chains the same three calls the live app makes (funcErNetworkEnhanceRun
% then funcErNetworkSkeletonRun, AnalyzERGUI/AnalyzER_app_extracted.m:13478-
% 13569) but with plain images + flat param structs instead of an app
% object, so it can run inside a sweep loop:
%   funcEnhanceRun -> erSkeletonRun -> analyzerRocAnalysis
%
% erSkeletonRun (not the bare funcSkeletonDispatcher/funcSkeletonRun) is
% used deliberately — it's what the live app actually uses to produce
% app.images.erSkeleton (mask/cisternae/fenestration handling, node/
% perimeter extraction), so scoring it here matches what the GT tab's ROC
% button would show for the same parameters.
%
% ARGUMENTS
%   im, gt, roiMask, cisterna, erMask, erFenestrations, cellBoundary, imBackground
%           – see erSkeletonRun / analyzerRocAnalysis for shapes.
%   pEnhance, pSkeleton – flat parameter structs (parameterSelectorBuildFlatParams).
%   tolerance, code     – see analyzerRocAnalysis.
%
% RETURNS
%   statsRow – 1-row table from analyzerRocAnalysis (TP/FP/FN/.../F1/MCC/...).
%   images   – struct with fields .enhanced, .skeleton, .rocRgb (for
%              per-combo preview in the UI; the sweep loop may discard
%              these to save memory when scanning many combos).

    [enhanced, orientations, ~] = funcEnhanceRun(im, pEnhance);

    skel = erSkeletonRun(enhanced, orientations, erMask, cisterna, ...
        erFenestrations, cellBoundary, imBackground, pSkeleton);

    [rocRgb, statsRow] = analyzerRocAnalysis(skel, gt, roiMask, cisterna, tolerance, code);

    images = struct('enhanced', enhanced, 'skeleton', skel, 'rocRgb', rocRgb);
end
