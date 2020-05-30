function tests = testZeroScattered
  tests = functiontests(localfunctions);
end

function setupOnce(~)
  addpath('../../../');
end

function testConstructor(testCase)

  incident_beam = ott.beam.abstract.Gaussian(2.0);
  shape = ott.shapes.Sphere(1.0);
  particle = ott.scat.shapeforce.Shape(shape, 1.2);

  beam = ott.beam.abstract.ZeroScattered(particle, incident_beam);

  testCase.verifyEqual(beam.type, 'total', 'type');
  testCase.verifyEqual(beam.incident_beam, incident_beam, 'ibeam');
  testCase.verifyEqual(beam.particle, particle, 'ibeam');

  % Verify dependent properties
  testCase.verifyEqual(beam.power, incident_beam.power, 'power');
  testCase.verifyEqual(beam.medium, incident_beam.medium, 'medium');
  testCase.verifyEqual(beam.omega, incident_beam.omega, 'omega');

  % Verify total_beam and scattered_beam
  testCase.verifyEqual(beam.scattered_beam, ott.beam.abstract.Empty(), 'sbeam');
  testCase.verifyEqual(beam.total_beam, incident_beam, 'tbeam');

end

% ott.beam.Beam cast tested in testScattered.
