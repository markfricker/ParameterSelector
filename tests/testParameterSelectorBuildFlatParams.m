classdef testParameterSelectorBuildFlatParams < matlab.unittest.TestCase
%TESTPARAMETERSELECTORBUILDFLATPARAMS  Unit tests for parameterSelectorBuildFlatParams.m.
%
% USAGE
%   results = runtests('tests/testParameterSelectorBuildFlatParams');
%   table(results)
%
% Verifies the standalone replica of AnalyzERproject_sandbox's
% genericBuildParams (AnalyzERGUI/AnalyzER_app_extracted.m:17000-17042):
% step-level fields carried through, combo values written in, method set,
% and no stray fields from OTHER methods' sub-structs leaking into pFinal.
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
        function makeFixture(tc)
            p = struct();
            p.use = true;
            p.method = 'vesselness';
            p.methodPrevious = 'vesselness';
            p.hminUse = true;
            p.hmin = 0.05;
            p.vesselness = struct('sigmaMin', 1, 'sigmaStep', 0.5, 'sigmaMax', 4, 'beta', 0.5, 'c', 0.15);
            p.ridge = struct('sigmaMin', 1, 'sigmaStep', 0.5, 'sigmaMax', 4, 'alpha', 0.5);
            tc.Fixture.stepCurrentParams = p;
        end
    end

    methods (Test)
        function testStepLevelFieldsCarriedThrough(tc)
            comboValues = struct('sigmaMin', 2, 'sigmaStep', 0.5, 'sigmaMax', 5, 'beta', 0.5, 'c', 0.15);
            pFinal = parameterSelectorBuildFlatParams(tc.Fixture.stepCurrentParams, 'vesselness', comboValues);
            tc.verifyEqual(pFinal.use, true);
            tc.verifyEqual(pFinal.hminUse, true);
            tc.verifyEqual(pFinal.hmin, 0.05);
        end

        function testComboValuesOverrideAndMethodIsSet(tc)
            comboValues = struct('sigmaMin', 2, 'sigmaStep', 0.5, 'sigmaMax', 5, 'beta', 0.5, 'c', 0.15);
            pFinal = parameterSelectorBuildFlatParams(tc.Fixture.stepCurrentParams, 'vesselness', comboValues);
            tc.verifyEqual(pFinal.sigmaMin, 2);
            tc.verifyEqual(pFinal.sigmaMax, 5);
            tc.verifyEqual(pFinal.method, 'vesselness');
        end

        function testOtherMethodsDoNotLeakIntoFlatParams(tc)
            comboValues = struct('sigmaMin', 2, 'sigmaStep', 0.5, 'sigmaMax', 5, 'beta', 0.5, 'c', 0.15);
            pFinal = parameterSelectorBuildFlatParams(tc.Fixture.stepCurrentParams, 'vesselness', comboValues);
            tc.verifyFalse(isfield(pFinal, 'ridge'));
            tc.verifyFalse(isfield(pFinal, 'vesselness'));
            tc.verifyFalse(isfield(pFinal, 'alpha'));  % ridge-only field
        end

        function testDifferentMethodUsesItsOwnComboValues(tc)
            comboValues = struct('sigmaMin', 3, 'sigmaStep', 1, 'sigmaMax', 6, 'alpha', 0.7);
            pFinal = parameterSelectorBuildFlatParams(tc.Fixture.stepCurrentParams, 'ridge', comboValues);
            tc.verifyEqual(pFinal.method, 'ridge');
            tc.verifyEqual(pFinal.alpha, 0.7);
            tc.verifyFalse(isfield(pFinal, 'beta'));  % vesselness-only field
        end
    end
end
