classdef Ellipsoid < ott.shape.Shape ...
    & ott.shape.mixin.StarShape ...
    & ott.shape.mixin.IsosurfSurfPoints ...
    & ott.shape.mixin.IntersectMinAll ...
    & ott.shape.mixin.IsSphereAbsProp
% Ellipsoid shape
%
% Properties:
%   - radii       -- Radii along Cartesian axes [X; Y; Z]
%
% Supported casts
%   - ott.shape.Spehre -- Only works when ellipsoid is a sphere
%   - ott.shape.AxisymInterp -- Only works when zRotSymmetry == 0
%   - ott.shape.PatchMesh

% This file is part of the optical tweezers toolbox.
% See LICENSE.md for information about using/distributing this file.

  properties
    radii
  end

  properties (Dependent)
    maxRadius          % Maximum particle radius
    volume             % Particle volume
    boundingBox        % Cartesian coordinate bounding box (no rot/pos)
    zRotSymmetry       % Degree of z rotational symmetry
    xySymmetry         % True if the particle is xy-plane mirror symmetric
    isSphere           % True if the particle is a sphere
  end

  methods
    function shape = Ellipsoid(varargin)
      % Construct a new ellipsoid
      %
      % Usage
      %   shape = Ellipsoid(radii, ...)
      %   Parameters can be passed as named arguments.
      %
      % Additional parameters passed to base.

      p = inputParser;
      p.addOptional('radii', [1, 2, 3]);
      p.KeepUnmatched = true;
      p.parse(varargin{:});
      unmatched = ott.utils.unmatchedArgs(p);

      shape = shape@ott.shape.Shape(unmatched{:});
      shape.radii = p.Results.radii;
    end

    function shape = ott.shape.Sphere(shape)
      % Convert object to a sphere (only works when ellipsoid is a sphere)

      assert(shape.isSphere, 'Shape must be a sphere for conversion');
      shape = ott.shape.Sphere(shape.radii(1));
    end

    function r = starRadii(shape, theta, phi)
      % Return the ellipsoid radii at specified angles
      %
      % Usage
      %   r = shape.starRadii(theta, phi)

      assert(all(size(theta) == size(phi)), ...
          'theta and phi must have same size');

      r = 1 ./ sqrt( (cos(phi).*sin(theta)/shape.radii(1)).^2 + ...
          (sin(phi).*sin(theta)/shape.radii(2)).^2 ...
          + (cos(theta)/shape.radii(3)).^2 );
    end
  end

  methods (Hidden)
    function n = normalsRtpInternal(shape, rtp)
      % calculates the normals for each requested point

      theta = rtp(2, :).';
      phi = rtp(3, :).';

      % r = 1/sqrt( cos(phi)^2 sin(theta)^2 / a^2 +
      %     sin(phi)^2 sin(theta)^2 / b2 + cos(theta)^2 / c^2 )
      % dr/dtheta = -r^3 ( cos(phi)^2 / a^2 + sin(phi)^2 / b^2
      %             - 1/c^2 ) sin(theta) cos(theta)
      % dr/dphi = -r^3 sin(phi) cos(phi) (1/b^2 - 1/a^2) sin(theta)^2
      % sigma = rhat + thetahat r^2 sin(theta) cos(theta) *
      %     ( cos(phi)^2/a^2 + sin(phi)^2/b^2 - 1/c^2 )
      %    + phihat r^2 sin(theta) sin(phi) cos(phi) (1/b^2 - 1//a^2)

      r = shape.starRadii(theta, phi);
      sigma_r = ones(size(r));
      sigma_theta = r.^2 .* sin(theta) .* cos(theta) .* ...
          ( (cos(phi)/shape.radii(1)).^2 ...
          + (sin(phi)/shape.radii(2)).^2 - 1/shape.radii(3)^2 );
      sigma_phi = r.^2 .* sin(theta) .* sin(phi) .* cos(phi) .* ...
          (1/shape.radii(2)^2 - 1/shape.radii(1)^2);
      sigma_mag = sqrt( sigma_r.^2 + sigma_theta.^2 + sigma_phi.^2 );

      n = [ sigma_r./sigma_mag, sigma_theta./sigma_mag, ...
          sigma_phi./sigma_mag ].';

      n = ott.utils.rtpv2xyzv(n, rtp);
    end

    function [locs, norms, dist] = intersectAllInternal(shape, x0, x1)

      % Call sphere method with transformed coordinates
      sph = ott.shape.Sphere(1.0);
      [locs, norms] = sph.intersectAllInternal(...
          x0 ./ shape.radii, x1 ./ shape.radii);

      % Transform back to original reference frame
      locs = locs .* shape.radii;
      norms = norms .* shape.radii;

      % Compute distances
      dist = vecnorm((locs - x0).*(x1 - x0))./vecnorm(x1 - x0);

    end

    function shape = scaleInternal(shape, sc)
      shape.radii = shape.radii * sc;
    end
  end

  methods % Getters/setters
    function shape = set.radii(shape, val)
      assert(isnumeric(val) && numel(val) == 3 && all(val >= 0), ...
          'radii must be positive numeric 3-vector');
      shape.radii = val(:);
    end

    function r = get.maxRadius(shape)
      % Calculate the maximum particle radius
      r = max(shape.radii);
    end

    function v = get.volume(shape)
      % Calculate the particle volume
      v = 4./3.*pi.*prod(shape.radii);
    end

    function bb = get.boundingBox(shape)
      bb = [-1, 1; -1, 1; -1, 1].*shape.radii;
    end

    function b = get.xySymmetry(~)
      b = true;
    end
    function q = get.zRotSymmetry(shape)
      if shape.radii(1) == shape.radii(2)
        q = 0;
      else
        q = 2;
      end
    end

    function b = get.isSphere(shape)
      b = all(shape.radii(1) == shape.radii);
    end
  end
end
