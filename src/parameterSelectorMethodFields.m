function fieldsOut = parameterSelectorMethodFields(defaults, currentParams, method)
%PARAMETERSELECTORMETHODFIELDS  List a method's own tunable fields + current values.
%
%   fieldsOut = parameterSelectorMethodFields(defaults, currentParams, method)
%
% Resolves `paramSource` wrapper aliasing exactly as AnalyzERproject_sandbox's
% genericBuildParams does: a wrapper method (e.g. 'featureType', whose
% defaults sub-struct is just `.paramSource = 'pc'`) reads its base fields
% from the resolved source method ('pc'), then overlays any extra fields of
% its own (e.g. 'pct' adds tensorBeta/tensorC on top of 'pc's fields).
%
% ARGUMENTS
%   defaults      – full step defaults struct, e.g. app.parameterDefaults.er.network.enhance
%   currentParams – full step current-value struct, e.g. app.parameters.er.network.enhance
%                   (same shape as defaults; may omit fields/methods not yet
%                   touched by the user, in which case defaults are used)
%   method        – method name to resolve, e.g. 'vesselness' or 'pct'
%
% RETURNS
%   fieldsOut – struct array with fields:
%                 .name    – parameter field name
%                 .current – its current value (from currentParams if
%                            present, else the default)
%               Field order matches defaults.(src) followed by any of the
%               wrapper method's own extra fields.

    if isfield(defaults, method) && isfield(defaults.(method), 'paramSource')
        src = defaults.(method).paramSource;
    else
        src = method;
    end

    names = {};
    vals  = {};

    if isfield(defaults, src)
        f = fieldnames(defaults.(src));
        for k = 1:numel(f)
            names{end+1} = f{k}; %#ok<AGROW>
            vals{end+1}  = parameterSelectorCurrentValue(currentParams, defaults, src, f{k}); %#ok<AGROW>
        end
    end

    if ~strcmp(method, src) && isfield(defaults, method)
        f = fieldnames(defaults.(method));
        for k = 1:numel(f)
            name = f{k};
            if strcmp(name, 'paramSource')
                continue
            end
            v = parameterSelectorCurrentValue(currentParams, defaults, method, name);
            idx = find(strcmp(names, name), 1);
            if isempty(idx)
                names{end+1} = name; %#ok<AGROW>
                vals{end+1}  = v; %#ok<AGROW>
            else
                vals{idx} = v;
            end
        end
    end

    if isempty(names)
        fieldsOut = struct('name', {}, 'current', {});
    else
        fieldsOut = struct('name', names(:), 'current', vals(:));
    end
end

function v = parameterSelectorCurrentValue(currentParams, defaults, method, field)
    if isfield(currentParams, method) && isfield(currentParams.(method), field)
        v = currentParams.(method).(field);
    else
        v = defaults.(method).(field);
    end
end
