function [items, selected] = parameterSelectorMethodItems(spec, stepIdx)
%PARAMETERSELECTORMETHODITEMS  Method list for the chosen steps of a sweep.
%
%   [items, selected] = parameterSelectorMethodItems(spec, stepIdx)
%
% items are 'Step label: method' for every candidate method of the steps
% spec.steps(stepIdx); selected are those of each step's current method.
% Steps with no method choice contribute nothing.

% SPDX-License-Identifier: GPL-2.0-or-later

    items = {};
    selected = {};
    for s = stepIdx(:)'
        st = spec.steps(s);
        for k = 1:numel(st.methods)
            items{end+1} = [st.label ': ' st.methods{k}]; %#ok<AGROW>
        end
        if ~isempty(st.methods) && isfield(st.current, 'method')
            selected{end+1} = [st.label ': ' st.current.method]; %#ok<AGROW>
        end
    end
    selected = intersect(selected, items, 'stable');
end
