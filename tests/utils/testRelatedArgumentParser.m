function tests = testRelatedArgumentParser
  tests = functiontests(localfunctions);
end

function setupOnce(testCase)
  addpath('../../');
end

function testExample(testCase)

  p = ott.utils.RelatedArgumentParser;
  p.addRequired('index_medium', 1.0);
  p.addOptional('speed0', 2.0);
  p.addOptional('speed');
  p.addRule('index_medium = speed0 ./ speed');
  p.parse('speed', 1.0);
  
  testCase.verifyEqual(p.RequiredResults.index_medium, 2, ...
    'AbsTol', 1e-15);

end

function testRelatedDepDefaults(testCase)

  p = ott.utils.RelatedArgumentParser;
  p.addRequired('param1', 1.0);
  p.addRequired('param2', 2.0);
  p.addRequired('param3');
  p.addRule('param3 = param1 + param2');
  p.parse();
  
  testCase.verifyEqual(p.RequiredResults.param1, 1.0, 'param1');
  testCase.verifyEqual(p.RequiredResults.param2, 2.0, 'param2');
  testCase.verifyEqual(p.RequiredResults.param3, 3.0, 'param3');

end

function testMultipleRules(testCase)

  p = ott.utils.RelatedArgumentParser;
  p.addOptional('param1', 1.0);
  p.addRequired('param2');
  p.addOptional('param3', 4.0);
  p.addRequired('param4');
  p.addRule('param4 = param1 + param2');
  p.addRule('param4 = param1 + param3');
  p.parse();
  
  testCase.verifyEqual(p.RequiredResults.param2, 4.0, 'param2');
  testCase.verifyEqual(p.RequiredResults.param4, 5.0, 'param3');

end

function testUnusedParameter(testCase)

  p = ott.utils.RelatedArgumentParser;
  p.addOptional('param1', 1.0);
  p.addRequired('param2');
  testCase.verifyWarning(@() p.parse('param2', 2, 'param1', 1), ...
    'ott:utils:RelatedArgumentParser:not_used');

end

function testUnusedOptionalRule(testCase)


  p = ott.utils.RelatedArgumentParser;
  p.addOptional('param1');
  p.addOptional('param2');
  p.addRequired('param3');
  p.addRule('param3 = param1');
  p.addRule('param3 = param2');
  p.parse('param1', 2.0);
  
  testCase.verifyEqual(p.RequiredResults.param3, 2.0);
  
end

function testDifferentShapes(testCase)

  testData = randn(3, 5);
  
  p = ott.utils.RelatedArgumentParser;
  p.addOptional('param1');
  p.addRequired('param2');
  p.addRule('param2 = param1');
  p.parse('param1', testData);
  
  testCase.verifyEqual(p.RequiredResults.param2, testData);
end