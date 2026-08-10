function pFinal = parameterSelectorBuildFlatParams(stepCurrentParams, method, comboValues)
%PARAMETERSELECTORBUILDFLATPARAMS  Build a flat execution parameter struct
%for one sweep combo, ready to pass to funcEnhanceRun/erSkeletonRun.
%
%   pFinal = parameterSelectorBuildFlatParams(stepCurrentParams, method, comboValues)
%
% Standalone replica of AnalyzERproject_sandbox's genericBuildParams
% (AnalyzERGUI/AnalyzER_app_extracted.m), which is hard-wired to
% app.parameters and so can't be called outside the app. Same merge:
%   1. copy step-level (non-struct) fields of stepCurrentParams verbatim
%      (use, hminUse, useParfor, ...)
%   2. copy every field of comboValues — already the fully paramSource-
%      resolved field set for `method` (see parameterSelectorMethodFields:
%      base/src fields plus any wrapper-method fields overlaid on top), so
%      no further aliasing needs resolving here
%   3. set pFinal.method
%
% ARGUMENTS
%   stepCurrentParams – the step's current full params struct, e.g.
%                        app.parameters.er.network.enhance. Used only for
%                        step-level fields — NOT for the chosen method's
%                        own field values, which come entirely from
%                        comboValues.
%   method            – this combo's chosen method name.
%   comboValues       – struct of that method's own field values for this
%                        combo (one entry of parameterSelectorExpandCombos'
%                        output).
%
% RETURNS
%   pFinal – flat struct, pFinal.method set, ready for funcEnhanceDispatcher
%            / funcEnhanceRun / funcSkeletonDispatcher / erSkeletonRun.

    pFinal = struct();
    fns = fieldnames(stepCurrentParams);
    for k = 1:numel(fns)
        f = fns{k};
        if ~isstruct(stepCurrentParams.(f))
            pFinal.(f) = stepCurrentParams.(f);
        end
    end

    f = fieldnames(comboValues);
    for k = 1:numel(f)
        pFinal.(f{k}) = comboValues.(f{k});
    end

    pFinal.method = method;
end
