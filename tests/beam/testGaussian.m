function tests = testGaussian
  tests = functiontests(localfunctions);
end

function setupOnce(testCase)
  addpath('../../');
end

function testConstruct(testCase)

  beam = ott.beam.Gaussian();
  testCase.verifyEqual(beam.power, 1.0, 'power');
  testCase.verifyEqual(beam.mapping, 'sin', 'mapping');
  testCase.verifyEqual(beam.polfield, [1, 1i], 'polfield');
  testCase.verifyEqual(beam.polbasis, 'cartesian', 'polbasis');

end

