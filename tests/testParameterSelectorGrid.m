classdef testParameterSelectorGrid < matlab.unittest.TestCase
%TESTPARAMETERSELECTORGRID  Unit tests for parameterSelectorStepRows and
%parameterSelectorExpandGrid (the schema-driven sweep table).
%
% USAGE
%   results = runtests(fullfile(pwd,'tests','testParameterSelectorGrid.m'));
%
% COVERAGE
%   Which fields a flat, a method and a nested step offer             - 3 tests
%   Aliased (paramSource) fields get the owner's path; option lists,
%   integer rounding, suggested range within the schema limits        - 3 tests
%   Union across methods, crossing within and between steps; method
%   set only when needed; shared fields; limit; empty range           - 6 tests
%
% Needs AnalyzERproject_sandbox/core/parameters on the path.

% SPDX-License-Identifier: GPL-2.0-or-later

    methods (TestClassSetup)
        function addPaths(tc) %#ok<MANU>
            here = fileparts(mfilename('fullpath'));
            addpath(fullfile(here, '..', 'src'));
            addpath(fullfile(here, '..', '..', 'AnalyzERproject_sandbox', 'core', 'parameters'));
        end
    end

    methods (Static, Access = private)
        function d = methodStep()
            d = struct('use', 1, 'method', 'marker', 'methodPrevious', 'marker');
            d.watershed = struct('threshold', 0.3, 'seedErosion', 2);
            d.marker    = struct('paramSource', 'watershed');
            d.pct       = struct('paramSource', 'watershed', 'tensorBeta', 0.5);
            d.li        = struct('bias', 1.0);
            d.otsu      = struct();
        end
        function r = tune(r, name, varargin)
            k = find(strcmp({r.parameter}, name));
            r(k).tune = true;
            if numel(varargin) == 3
                r(k).min = varargin{1}; r(k).inc = varargin{2}; r(k).max = varargin{3};
            end
        end
    end

    methods (Test)
        function testFlatStepLeavesOutControlFields(tc)
            d = struct('use',1,'minVolumeUse',1,'minVolume',0.05,'minSections',1, ...
                'channel1Use',1,'sectionFirst',0,'fillPrevious','x','input','auto');
            r = parameterSelectorStepRows('a.b.refine', d, d);
            tc.verifyEqual(sort({r.parameter}), sort({'minVolumeUse','minVolume','minSections'}));
            tc.verifyEqual(r(strcmp({r.parameter},'minVolumeUse')).type, 'logical');
            tc.verifyEqual(r(strcmp({r.parameter},'minVolume')).path, 'a.b.refine.minVolume');
        end

        function testCurrentValueUsed(tc)
            d = struct('minVolume', 0.05);  c = struct('minVolume', 0.2);
            r = parameterSelectorStepRows('a.b.c', c, d);
            tc.verifyEqual(r.current, 0.2);
        end

        function testNestedGroup(tc)
            d = struct('minArea', 0.1, 'refine', struct('use', 1, 'iterations', 5));
            r = parameterSelectorStepRows('o.r.auto', d, d);
            k = strcmp({r.parameter}, 'iterations');
            tc.verifyEqual(r(k).step, 'o.r.auto.refine');
            tc.verifyEqual(r(k).path, 'o.r.auto.refine.iterations');
        end

        function testCurrentMethodOnlyByDefault(tc)
            d = testParameterSelectorGrid.methodStep();
            r = parameterSelectorStepRows('o.e.segment', d, d);
            tc.verifyEqual(unique({r.method}), {'marker'});
            tc.verifyEqual(sort({r.path}), sort({'o.e.segment.watershed.threshold','o.e.segment.watershed.seedErosion'}));
        end

        function testAliasedOwnFieldPath(tc)
            d = testParameterSelectorGrid.methodStep();
            r = parameterSelectorStepRows('o.e.segment', d, d, {'pct'});
            tc.verifyEqual(r(strcmp({r.parameter},'tensorBeta')).path, 'o.e.segment.pct.tensorBeta');
            tc.verifyEqual(r(strcmp({r.parameter},'threshold')).path, 'o.e.segment.watershed.threshold');
        end

        function testEnumIntegerAndLimits(tc)
            d = struct('fill', '3D', 'count', 1, 'sensitivity', 0.8);
            meta = containers.Map();
            meta('a.b.c.fill') = struct('type','enum','options',{{'3D','2D'}});
            meta('a.b.c.sensitivity') = struct('type','numeric','class','floating','min',0,'max',1);
            meta('a.b.c.count') = struct('type','numeric','class','integer');
            r = parameterSelectorStepRows('a.b.c', d, d, {}, meta);
            tc.verifyEqual(r(strcmp({r.parameter},'fill')).choices, {'3D','2D'});
            tc.verifyTrue(r(strcmp({r.parameter},'count')).integer);
            s = r(strcmp({r.parameter},'sensitivity'));
            tc.verifyEqual(s.max, 1);
            tc.verifyLessThanOrEqual(s.min, 0.8);
        end

        function testUnionAcrossMethods(tc)
            d = testParameterSelectorGrid.methodStep();
            r = parameterSelectorStepRows('o.e.segment', d, d, {'li','marker','otsu'});
            r = testParameterSelectorGrid.tune(r, 'bias', 0.5, 0.5, 1.5);          % 3
            r = testParameterSelectorGrid.tune(r, 'threshold', 0.1, 0.1, 0.2);     % 2
            c = parameterSelectorExpandGrid(r, {'o.e.segment', {'li','marker','otsu'}, 'marker'});
            tc.verifyEqual(numel(c), 3 + 2 + 1, 'union, with otsu once');
            methodsSet = arrayfun(@(x) x.set{1,2}, c, 'UniformOutput', false);
            tc.verifyEqual(sum(strcmp(methodsSet,'otsu')), 1);
            tc.verifyEqual(c(1).set{1,1}, 'o.e.segment.method');
        end

        function testCrossBetweenSteps(tc)
            d = struct('a', 1.5, 'b', 2.5);
            r1 = testParameterSelectorGrid.tune(parameterSelectorStepRows('s.m.one', d, d), 'a', 1, 1, 3);
            r2 = testParameterSelectorGrid.tune(parameterSelectorStepRows('s.m.two', d, d), 'b', 1, 1, 2);
            c = parameterSelectorExpandGrid([r1 r2], {});
            tc.verifyEqual(numel(c), 6);
            v = cell2mat(arrayfun(@(x) [x.set{:,2}], c', 'UniformOutput', false));
            tc.verifyEqual(size(unique(v, 'rows'), 1), 6);
        end

        function testMethodNotSetWhenUnchanged(tc)
            d = testParameterSelectorGrid.methodStep();
            r = parameterSelectorStepRows('o.e.segment', d, d);
            r = testParameterSelectorGrid.tune(r, 'threshold', 0.1, 0.1, 0.3);
            c = parameterSelectorExpandGrid(r, {'o.e.segment', {'marker'}, 'marker'});
            tc.verifyEqual(size(c(1).set), [1 2]);
            tc.verifyEqual(c(1).set{1,1}, 'o.e.segment.watershed.threshold');
            tc.verifyEqual(c(3).set{1,2}, 0.3, 'no floating-point tail');
            c = parameterSelectorExpandGrid(r, {'o.e.segment', {'marker'}, 'li'});
            tc.verifyEqual(c(1).set{1,1}, 'o.e.segment.method', 'a different single method is set');
        end

        function testLogicalAndIntegerValues(tc)
            d = struct('flagUse', 1, 'count', 3);
            meta = containers.Map();
            meta('a.b.c.count') = struct('type','numeric','class','integer');
            r = parameterSelectorStepRows('a.b.c', d, d, {}, meta);
            r = testParameterSelectorGrid.tune(r, 'flagUse');
            r = testParameterSelectorGrid.tune(r, 'count', 1.2, 0.4, 2.1);
            c = parameterSelectorExpandGrid(r, {});
            tc.verifyEqual(numel(c), 2 * 2, 'rounded to the integers 1 and 2');
        end

        function testWholeNumberDefaultStaysFractional(tc)
            d = struct('bias', 1.0);
            r = testParameterSelectorGrid.tune(parameterSelectorStepRows('a.b.c', d, d), 'bias', 0.5, 0.5, 1.5);
            c = parameterSelectorExpandGrid(r, {});
            tc.verifyEqual(cellfun(@(x) x, arrayfun(@(y) y.set{1,2}, c, 'UniformOutput', false)), [0.5 1 1.5]);
        end

        function testLimit(tc)
            d = struct('a', 1.5, 'b', 2.5);
            r = parameterSelectorStepRows('s.m.one', d, d);
            r = testParameterSelectorGrid.tune(r, 'a', 1, 0.001, 2);
            r = testParameterSelectorGrid.tune(r, 'b', 1, 0.001, 2);
            tc.verifyError(@() parameterSelectorExpandGrid(r, {}, 1000), 'parameterSelectorExpandGrid:tooMany');
        end

        function testEmptyRange(tc)
            d = struct('a', 1.5);
            r = testParameterSelectorGrid.tune(parameterSelectorStepRows('s.m.one', d, d), 'a', 3, 1, 1);
            tc.verifyError(@() parameterSelectorExpandGrid(r, {}), 'parameterSelectorExpandGrid:emptyRange');
        end
    end
end
