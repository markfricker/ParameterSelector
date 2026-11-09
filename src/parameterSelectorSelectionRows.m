function [rows, methods] = parameterSelectorSelectionRows(spec, stepIdx, methodItems)
%PARAMETERSELECTORSELECTIONROWS  Sweep table for the steps and methods chosen.
%
%   [rows, methods] = parameterSelectorSelectionRows(spec, stepIdx, methodItems)
%
%   spec         window specification: .meta and .steps(k) with .id .label
%                .current .defaults .methods (see funcSweepSpec in the app)
%   stepIdx      the chosen steps
%   methodItems  the chosen 'Step label: method' items; a step with none
%                chosen uses its current method
%   rows         parameterSelectorStepRows output for all the chosen steps
%   methods      N-by-3 cell for parameterSelectorExpandGrid

% SPDX-License-Identifier: GPL-2.0-or-later

    rows = [];
    methods = cell(0, 3);
    for s = stepIdx(:)'
        st = spec.steps(s);
        chosen = {};
        prefix = [st.label ': '];
        for k = 1:numel(methodItems)
            if startsWith(methodItems{k}, prefix)
                chosen{end+1} = extractAfter(methodItems{k}, strlength(prefix)); %#ok<AGROW>
            end
        end
        chosen = cellstr(chosen);
        r = parameterSelectorStepRows(st.id, st.current, st.defaults, chosen, spec.meta);
        if isempty(rows), rows = r; else, rows = [rows, r]; end %#ok<AGROW>
        if ~isempty(st.methods)
            if isempty(chosen), chosen = {st.current.method}; end
            methods(end+1, :) = {st.id, chosen, st.current.method}; %#ok<AGROW>
        end
    end
end
