classdef testParameterSelectorMethodFields < matlab.unittest.TestCase
%TESTPARAMETERSELECTORMETHODFIELDS  Unit tests for parameterSelectorMethodFields.m.
%
% USAGE
%   results = runtests('tests/testParameterSelectorMethodFields');
%   table(results)
%
% Uses a small synthetic defaults/current struct pair that mirrors the
% real enhance-step paramSource relationships (pc / pct / featureType,
% see AnalyzERGUI/AnalyzER_app_extracted.m:3572-3586) without depending on
% AnalyzERproject_sandbox being on the path.
%
% NOTE: fixtures are held in a plain instance property (Fixture), not the
% framework's TestCase.TestData -- that property was removed from
% matlab.unittest.TestCase as of R2026a Update 3.

    properties
        Fixture
    end

    methods (TestClassSetup)
        function addPaths(tc) %#ok<MANU>
            rootDir = fullfile(fileparts(mfilename('fullpath')), '..', 'src');
            addpath(rootDir);
        end
    end

    methods (TestMethodSetup)
        function makeFixtures(tc)
            d = struct();
            d.pc = struct('scales', 4, 'orientations', 6, 'minWaveLength', 5);
            d.pct = struct('paramSource', 'pc', 'tensorBeta', 0.5, 'tensorC', 0.15);
            d.featureType = struct('paramSource', 'pc');
            d.vesselness = struct('sigmaMin', 1, 'sigmaStep', 0.5, 'sigmaMax', 4, 'beta', 0.5, 'c', 0.15);
            tc.Fixture.defaults = d;

            c = d;
            c.vesselness.sigmaMin = 2;   % simulate a live UI-edited value
            c.pc.scales = 5;             % simulate a live UI-edited base value
            tc.Fixture.current = c;
        end
    end

    methods (Test)
        function testPlainMethodUsesCurrentValues(tc)
            f = parameterSelectorMethodFields(tc.Fixture.defaults, tc.Fixture.current, 'vesselness');
            names = {f.name};
            tc.verifyEqual(sort(names), sort({'sigmaMin','sigmaStep','sigmaMax','beta','c'}));
            tc.verifyEqual(f(strcmp(names,'sigmaMin')).current, 2);   % current overrides default
            tc.verifyEqual(f(strcmp(names,'beta')).current, 0.5);     % falls back to default
        end

        function testWrapperWithNoOwnFieldsResolvesToSource(tc)
            % featureType has only paramSource='pc' -- its field list must
            % be exactly pc's fields, read from the CURRENT pc values.
            f = parameterSelectorMethodFields(tc.Fixture.defaults, tc.Fixture.current, 'featureType');
            names = {f.name};
            tc.verifyEqual(sort(names), sort({'scales','orientations','minWaveLength'}));
            tc.verifyEqual(f(strcmp(names,'scales')).current, 5);  % from current.pc, not default.pc
        end

        function testWrapperWithOwnFieldsUnionsWithSource(tc)
            % pct = pc's base fields + its own tensorBeta/tensorC overlaid.
            f = parameterSelectorMethodFields(tc.Fixture.defaults, tc.Fixture.current, 'pct');
            names = {f.name};
            tc.verifyEqual(sort(names), sort({'scales','orientations','minWaveLength','tensorBeta','tensorC'}));
            tc.verifyEqual(f(strcmp(names,'scales')).current, 5);        % base, from current.pc
            tc.verifyEqual(f(strcmp(names,'tensorBeta')).current, 0.5);  % own field, current==default here
        end

        function testCurrentParamsMissingMethodFallsBackToDefaults(tc)
            % currentParams entirely omits 'ridge' -- every value must come
            % straight from defaults without erroring.
            d = tc.Fixture.defaults;
            d.ridge = struct('sigmaMin', 1, 'sigmaStep', 0.5, 'sigmaMax', 4, 'alpha', 0.5);
            currentSparse = struct('pc', d.pc);  % 'ridge' deliberately absent

            f = parameterSelectorMethodFields(d, currentSparse, 'ridge');
            names = {f.name};
            tc.verifyEqual(sort(names), sort({'sigmaMin','sigmaStep','sigmaMax','alpha'}));
            tc.verifyEqual(f(strcmp(names,'sigmaMin')).current, 1);
        end
    end
end
