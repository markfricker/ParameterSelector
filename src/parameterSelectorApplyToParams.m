function paramsOut = parameterSelectorApplyToParams(defaults, currentParams, method, values)
%PARAMETERSELECTORAPPLYTOPARAMS  Write one winning combo's values back into
%a live-shaped params struct (app.parameters.<strand>.<module>.<step>), so
%the result can be assigned straight back onto the running app.
%
%   paramsOut = parameterSelectorApplyToParams(defaults, currentParams, method, values)
%
% ARGUMENTS
%   defaults      – full step defaults struct, e.g.
%                    app.parameterDefaults.er.network.enhance. Needed to
%                    tell, for a wrapper method, which of `values`' fields
%                    are the wrapper's own (e.g. pct.tensorBeta) versus the
%                    resolved source method's base fields (e.g. pc.scales)
%                    — that split isn't preserved in the flat `values`
%                    struct itself (see parameterSelectorMethodFields).
%   currentParams – the step's current full params struct, used as the
%                    base so every OTHER method's settings are preserved
%                    untouched.
%   method        – the winning combo's method name for this step.
%   values        – that method's own field values for the winning combo
%                    (parameterSelectorExpandCombos output).
%
% RETURNS
%   paramsOut – currentParams with `method`/`methodPrevious` set to
%               `method`, and the appropriate sub-struct(s) updated with
%               `values` — same shape as currentParams, ready to assign
%               back onto app.parameters.<strand>.<module>.<step>.

    paramsOut = currentParams;
    paramsOut.method = method;
    paramsOut.methodPrevious = method;

    if isfield(defaults, method) && isfield(defaults.(method), 'paramSource')
        src = defaults.(method).paramSource;
    else
        src = method;
    end

    ownFields = {};
    if ~strcmp(method, src) && isfield(defaults, method)
        ownFields = setdiff(fieldnames(defaults.(method)), {'paramSource'});
    end

    f = fieldnames(values);
    for k = 1:numel(f)
        name = f{k};
        if ismember(name, ownFields)
            paramsOut.(method).(name) = values.(name);
        else
            paramsOut.(src).(name) = values.(name);
        end
    end
end
