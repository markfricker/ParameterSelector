%MANUALLAUNCHPARAMETERSELECTOR  Throwaway manual sanity check for the
%Phase 2 ParameterSelector.mlapp UI, using a noisy, moderate-contrast wavy
%line as the synthetic image/GT pair, plus a realistic (hand-copied)
%enhance/skeleton defaults struct so the method checklists look like the
%real app's, instead of the automated smoke test's single-method stub.
%
% NOT an automated test (no 'test' prefix, not a matlab.unittest.TestCase)
% -- runtests() will not pick this up. Run it directly:
%
%   cd tests
%   manualLaunchParameterSelector
%
% Select 'vesselness' (Enhance) and 'hysteresis' (Skeleton) when you click
% "Run sweep" -- those are the only two methods this script's path setup
% actually has dependencies for (see testParameterSelectorRunSweep.m's
% header comment). Other listed methods will error if you sweep them here;
% that's expected on this machine, not a bug -- the full method list is
% only for checking the checklist UI looks right, not for exercising every
% algorithm.
%
% Unlike the first cut of this script (a stark, saturated bar that every
% reasonable parameter choice detected perfectly, F1=1.0 regardless of
% sigma/threshold -- correct behaviour, but useless for *seeing* the sweep
% do anything), this image is noisy and moderate-contrast enough that F1
% genuinely varies across sensible ranges: build the sweep table, tick
% "tune" on the enhance step's sigmaMin (try 1:1:3) and sigmaMax (try
% 2:1:6), and the skeleton step's threshHigh (try 0.35:0.15:0.65) and
% threshLow (try 0.2:0.1:0.4) -- confirmed via a standalone grid check to
% range from F1=0.35 (too-permissive threshold, high FP) up to F1=1.0
% (clean detection), so the ranked results table should show real spread,
% not a wall of identical top scores.

%% Path setup -- same siblings as the automated smoke test.
siblingRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src'));

deps = { ...
    fullfile(siblingRoot, 'AnalyzERproject_sandbox', 'core'), ...
    fullfile(siblingRoot, 'CurvilinearFilters_sandbox'), ...
    fullfile(siblingRoot, 'Skeletonization_sandbox'), ...
    fullfile(siblingRoot, 'NetworkCommon_sandbox')};
for k = 1:numel(deps)
    if ~isfolder(deps{k})
        error('manualLaunchParameterSelector:missingDependency', ...
            'Sibling dependency not found: %s', deps{k});
    end
end
for k = 1:3
    addpath(genpath(deps{k}));
end
addpath(deps{4});

%% Synthetic image + ground truth: a noisy, moderate-contrast wavy line.
% GT is the clean 1px centerline, independent of the noise added below --
% grid-checked standalone to give F1 in [0.35, 1.0] over the ranges quoted
% in the header comment, so sweeping actually shows visible separation.
rng(7);
n = 96;
x = 5:90;
y = round(48 + 15 * sin((x - 5) / 85 * 2 * pi));
lineMask = false(n, n);
lineMask(sub2ind([n n], y, x)) = true;
gt = lineMask;

imClean = single(imdilate(lineMask, strel('disk', 1)));
imClean = imgaussfilt(imClean, 1.2) * 0.5;   % moderate contrast, peak ~0.5
noise = 0.08 * randn(n, n, 'single');
im = single(mat2gray(imClean + noise));

roiMask = true(n, n);
cisterna = [];
erMask = true(n, n);
erFenestrations = [];
cellBoundary = [];
imBackground = [];

%% Enhance defaults -- hand-copied from
%  AnalyzERGUI/AnalyzER_app_extracted.m:3560-3634 (funcParameterDefaultsErNetworkEnhance)
%  so the method checklist matches the real app.
enhanceDefaults = struct();
enhanceDefaults.use = true;
enhanceDefaults.method = 'vesselness';
enhanceDefaults.methodPrevious = 'vesselness';
enhanceDefaults.guidedFilterUse = false;
enhanceDefaults.useParfor = false;

enhanceDefaults.pc = struct('scales', 4, 'orientations', 6, 'minWaveLength', 5, ...
    'multiplier', 2.1, 'sigmaOnFrequency', 0.55, 'k', 2, 'cutOff', 0.3, 'g', 5, 'noiseMethod', -1);
enhanceDefaults.pct = struct('paramSource', 'pc', 'tensorBeta', 0.5, 'tensorC', 0.15);
enhanceDefaults.featureType = struct('paramSource', 'pc');
enhanceDefaults.vesselness = struct('sigmaMin', 1, 'sigmaStep', 1, 'sigmaMax', 2, 'beta', 0.5, 'c', 0.15);
enhanceDefaults.ridge = struct('sigmaMin', 1, 'sigmaStep', 0.5, 'sigmaMax', 4, 'alpha', 0.5);
enhanceDefaults.neuriteness = struct('sigmaMin', 2);
enhanceDefaults.soagk = struct('sigmaMin', 0.5, 'sigmaStep', 0.5, 'sigmaMax', 4, 'orientations', 6, 'anisotropy', 3.0);
enhanceDefaults.steerGauss = struct('sigmaMin', 0.5, 'sigmaStep', 0.5, 'sigmaMax', 4, 'orientations', 23);
enhanceDefaults.bowlerHat = struct('sigmaMin', 3, 'sigmaStep', 1, 'sigmaMax', 5, 'orientations', 12);
enhanceDefaults.mfatLambda = struct('sigmaMin', 1, 'sigmaStep', 0.5, 'sigmaMax', 4, 'tau', 0.03, 'tau2', 0.15, 'd', 0.6);
enhanceDefaults.mfatProb = struct('sigmaMin', 1, 'sigmaStep', 0.5, 'sigmaMax', 4, 'tau', 0.03, 'tau2', 0.15, 'd', 0.6);
enhanceDefaults.nERdy = struct('threshold', -1);

enhanceCurrent = enhanceDefaults;  % no live overrides for this manual test

%% Skeleton defaults -- hand-copied from
%  AnalyzERGUI/AnalyzER_app_extracted.m:3636-3691 (funcParameterDefaultsErNetworkSkeleton),
%  but with hminUse forced false and repairUse false so a plain 'hysteresis'/
%  'WS + NMS' run doesn't need the h-minima/junction-repair dependencies
%  this manual script's path setup doesn't add.
skeletonDefaults = struct();
skeletonDefaults.method = 'hysteresis';
skeletonDefaults.methodPrevious = 'hysteresis';
skeletonDefaults.pruneLength = 0;
skeletonDefaults.minArea = 1;
skeletonDefaults.gccUse = false;
skeletonDefaults.maskUse = true;
skeletonDefaults.hminUse = false;
skeletonDefaults.hmin = 0.05;
skeletonDefaults.repairUse = false;
skeletonDefaults.repairRadius = 10;
skeletonDefaults.repairMinCluster = 2;
skeletonDefaults.repairMinIntensity = 0.1;

skeletonDefaults.hysteresis = struct('threshHigh', 0.5, 'threshLow', 0.3, 'threshold', 0.3);
skeletonDefaults.adaptiveHysteresis = struct('ratio', 0.4, 'kSigma', 0);
skeletonDefaults.nms = struct('radius', 1.5, 'threshold', 0);
skeletonDefaults.sauvola = struct('windowSize', 15, 'k', 0.2, 'r', 0.5);
skeletonDefaults.phansalkar = struct('windowSize', 15, 'k', 0.25, 'r', 0.5, 'p', 2.0, 'q', 10.0);
skeletonDefaults.distWatershed = struct('threshold', 0.3, 'threshLow', 0, 'smoothSigma', 1.0, 'hMinima', 2);
skeletonDefaults.hessianCenterline = struct('sigma', 1.5, 'threshold', 0);
skeletonDefaults.hysteresis2 = struct('sensitivity', 0.5);
% ridgeWatershed and 'WS + NMS' have no tunable sub-struct (see startupFcn's
% funcGenericMethodsFromDefaults(..., {}, {'ridgeWatershed','WS + NMS'}) call).

skeletonCurrent = skeletonDefaults;

tolerance = 2;
tubuleDiameterTarget = 4;
code = 'manual-test';

%% Launch.
ps = ParameterSelector(im, gt, roiMask, cisterna, erMask, erFenestrations, cellBoundary, imBackground, ...
    enhanceCurrent, enhanceDefaults, skeletonCurrent, skeletonDefaults, tolerance, tubuleDiameterTarget, code);
uiwait(ps.UIFigure);

if isvalid(ps)
    outputParams = ps.OutputParams;
    delete(ps);
    if isempty(outputParams)
        disp('Cancelled -- no parameters applied.');
    else
        disp('Applied enhance params:');
        disp(outputParams.enhance);
        disp('Applied skeleton params:');
        disp(outputParams.skeleton);
    end
else
    disp('App was closed/deleted unexpectedly.');
end
