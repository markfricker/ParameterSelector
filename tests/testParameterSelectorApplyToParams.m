classdef testParameterSelectorApplyToParams < matlab.unittest.TestCase
%TESTPARAMETERSELECTORAPPLYTOPARAMS  Unit tests for parameterSelectorApplyToParams.m.
%
% USAGE
%   results = runtests('tests/testParameterSelectorApplyToParams');
%   table(results)
%
% Round-trips parameterSelectorMethodFields -> (simulated winning combo) ->
% parameterSelectorApplyToParams, and checks the reconstructed nested
% params struct is what app.parameters.<strand>.<module>.<step> expects:
% winning values land in the right sub-struct(s), other methods'
% sub-structs are preserved untouched, method/methodPrevious updated.
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
            d.method = 'featureType';
            d.methodPrevious = 'featureType';
            d.use = true;
            d.pc = struct('scales', 4, 'orientations', 6);
            d.pct = struct('paramSource', 'pc', 'tensorBeta', 0.5, 'tensorC', 0.15);
            d.featureType = struct('paramSource', 'pc');
            d.vesselness = struct('sigmaMin', 1, 'sigmaStep', 0.5, 'sigmaMax', 4, 'beta', 0.5, 'c', 0.15);
            tc.Fixture.defaults = d;
            tc.Fixture.current = d;  % identical for this test -- current == default
        end
    end

    methods (Test)
        function testPlainMethodWritesDirectlyIntoOwnSubstruct(tc)
            values = struct('sigmaMin', 2, 'sigmaStep', 0.5, 'sigmaMax', 5, 'beta', 0.5, 'c', 0.15);
            out = parameterSelectorApplyToParams(tc.Fixture.defaults, tc.Fixture.current, 'vesselness', values);
            tc.verifyEqual(out.method, 'vesselness');
            tc.verifyEqual(out.methodPrevious, 'vesselness');
            tc.verifyEqual(out.vesselness.sigmaMin, 2);
            tc.verifyEqual(out.vesselness.sigmaMax, 5);
        end

        function testWrapperWithNoOwnFieldsWritesIntoSource(tc)
            % featureType has no fields of its own -- winning values must
            % land in pc (the resolved source), not in featureType itself.
            values = struct('scales', 7, 'orientations', 6);
            out = parameterSelectorApplyToParams(tc.Fixture.defaults, tc.Fixture.current, 'featureType', values);
            tc.verifyEqual(out.method, 'featureType');
            tc.verifyEqual(out.pc.scales, 7);
            tc.verifyFalse(isfield(out.featureType, 'scales'));
        end

        function testWrapperWithOwnFieldsSplitsAcrossBothSubstructs(tc)
            % pct: 'scales'/'orientations' are pc's base fields, but
            % 'tensorBeta'/'tensorC' are pct's own -- each must land in the
            % correct sub-struct.
            values = struct('scales', 8, 'orientations', 6, 'tensorBeta', 0.7, 'tensorC', 0.2);
            out = parameterSelectorApplyToParams(tc.Fixture.defaults, tc.Fixture.current, 'pct', values);
            tc.verifyEqual(out.pc.scales, 8);
            tc.verifyEqual(out.pct.tensorBeta, 0.7);
            tc.verifyEqual(out.pct.tensorC, 0.2);
        end

        function testOtherMethodsSubstructsPreservedUntouched(tc)
            values = struct('sigmaMin', 2, 'sigmaStep', 0.5, 'sigmaMax', 5, 'beta', 0.5, 'c', 0.15);
            out = parameterSelectorApplyToParams(tc.Fixture.defaults, tc.Fixture.current, 'vesselness', values);
            tc.verifyEqual(out.pc, tc.Fixture.current.pc);
            tc.verifyEqual(out.pct, tc.Fixture.current.pct);
        end
    end
end
