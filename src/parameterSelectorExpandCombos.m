function combos = parameterSelectorExpandCombos(rows)
%PARAMETERSELECTOREXPANDCOMBOS  Build the combined enhance x skeleton sweep grid.
%
%   combos = parameterSelectorExpandCombos(rows)
%
% ARGUMENTS
%   rows – struct array, one entry per (step, method, parameter), with
%          fields:
%            .step      – 'enhance' | 'skeleton'
%            .method    – method name, e.g. 'vesselness'
%            .parameter – field name, e.g. 'sigmaMin'
%            .current   – current/fixed value (used verbatim when tune=false)
%            .tune      – logical; sweep this field over min:inc:max
%            .min, .inc, .max – sweep range (ignored when tune=false)
%
%          Every field of every user-selected candidate method must have a
%          row (see parameterSelectorMethodFields) — untuned rows still
%          supply that field's fixed current value to every combo.
%
% RETURNS
%   combos – struct array, one entry per resulting combination:
%              .enhanceMethod, .enhanceValues  – chosen enhance method +
%                                                 struct of its own field values
%              .skeletonMethod, .skeletonValues – same, for skeleton
%
% COMBINATORICS
%   Within a step, combos are UNIONED across candidate methods — picking
%   method B never multiplies method A's parameter ranges into the grid,
%   unlike the legacy AnalyzER_v2/FungalNetwork parameter_selector tools,
%   which shared one flat table across every checked method and so
%   cross-producted irrelevant methods' rows together. Each method's own
%   tuned fields ARE cross-producted together (mixed-radix "odometer"
%   expansion, same algorithm as those legacy tools' fnc_parameter_sequence).
%   The two steps are then cross-joined, since assessing the enhance+
%   skeleton combination jointly is the whole point of this tool.

    stepNames = {'enhance', 'skeleton'};
    stepMethodCombos = struct();
    for si = 1:numel(stepNames)
        stepName = stepNames{si};
        mask = strcmp({rows.step}, stepName);
        stepRows = rows(mask);
        methodsHere = unique({stepRows.method}, 'stable');

        acc = struct('method', {}, 'values', {});
        for mi = 1:numel(methodsHere)
            m = methodsHere{mi};
            mRows = stepRows(strcmp({stepRows.method}, m));
            mCombos = parameterSelectorExpandMethodRows(mRows);
            for ci = 1:numel(mCombos)
                acc(end+1) = struct('method', m, 'values', mCombos(ci)); %#ok<AGROW>
            end
        end
        stepMethodCombos.(stepName) = acc;
    end

    eList = stepMethodCombos.enhance;
    sList = stepMethodCombos.skeleton;
    if isempty(eList) || isempty(sList)
        error('parameterSelectorExpandCombos:empty', ...
            ['At least one candidate method (with a full field set) is ' ...
             'required for both the enhance and skeleton steps.']);
    end

    combos = struct('enhanceMethod', {}, 'enhanceValues', {}, ...
                     'skeletonMethod', {}, 'skeletonValues', {});
    n = 0;
    for i = 1:numel(eList)
        for j = 1:numel(sList)
            n = n + 1;
            combos(n).enhanceMethod  = eList(i).method;
            combos(n).enhanceValues  = eList(i).values;
            combos(n).skeletonMethod = sList(j).method;
            combos(n).skeletonValues = sList(j).values;
        end
    end
end

function mCombos = parameterSelectorExpandMethodRows(mRows)
%PARAMETERSELECTOREXPANDMETHODROWS  Mixed-radix cross-product over one
%method's own rows (private helper).

    n = numel(mRows);
    if n == 0
        mCombos = struct([]);
        return
    end

    Pval = cell(n, 1);
    for i = 1:n
        if mRows(i).tune
            Pval{i} = mRows(i).min:mRows(i).inc:mRows(i).max;
            if isempty(Pval{i})
                error('parameterSelectorExpandCombos:emptyRange', ...
                    'Parameter "%s" (method "%s") has an empty tune range [%.4g:%.4g:%.4g].', ...
                    mRows(i).parameter, mRows(i).method, mRows(i).min, mRows(i).inc, mRows(i).max);
            end
        else
            Pval{i} = mRows(i).current;
        end
    end

    nV      = cellfun(@numel, Pval);
    cpn     = cumprod(nV);
    nCombos = cpn(end);

    combosCell = cell(nCombos, 1);
    for k = 1:nCombos
        s = struct();
        for i = 1:n
            if i == 1
                idx = mod(k - 1, nV(1)) + 1;
            else
                idx = mod(floor((k - 1) / cpn(i - 1)), nV(i)) + 1;
            end
            s.(mRows(i).parameter) = Pval{i}(idx);
        end
        combosCell{k} = s;
    end
    mCombos = [combosCell{:}];
end
