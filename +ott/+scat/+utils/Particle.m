classdef (Abstract) Particle < ott.utils.RotateHelper
% Describes the abstract interface for particle.
% Inherits from :class:`ott.utils.RotateHelper`.
%
% Particle-centric scattering methods should inherit from this class.
% Particles which describe geometric shapes can choose to inherit from
% this class and the geometric shape class, or use the
% :class:`ShapeProperty` to declare a `shape` property in the class.
%
% Abstract properties
%   - position    -- Position of the particle [3xN]
%   - rotation    -- Orientation of the particle [3x3]
%
% Methods
%   - force       -- Calculate force on particle in beam
%   - torque      -- Calculate torque on particle in beam
%   - forcetorque -- Calculate force and torque on particle in beam
%
% Abstract methods
%   - rotate      -- Apply rotation to particle
%   - scatter     -- Calculate scattered beam
%   - forceInternal       -- Method called by `force`
%   - torqueInternal      -- Method called by `torque`
%   - forcetorqueInternal -- Method called by `forcetorque`

% Copyright 2020 Isaac Lenton
% This file is part of OTT, see LICENSE.md for information about
% using/distributing this file

  properties (Abstract)
    position    % Position of the particle [3xN]
    rotation    % Orientation of the particle [3x3]
  end

  methods (Abstract)
    scatter              % Calculate scattered beam
  end

  methods (Abstract, Hidden)
    forceInternal        % Calculate force on particle in beam
    torqueInternal       % Calculate torque on particle in beam
  end

  methods
    function varargout = force(particle, beam, varargin)
      % Calculate the force from a beam on a particle.
      % For details on usage/arguments see :meth:`forcetorque`.
      %
      % Usage
      %   force = particle.force(beam, ...)

      [varargout{1:nargout}] = particle.forceInternal(beam, varargin{:});
    end

    function varargout = torque(particle, beam, varargin)
      % Calculate the torque from a beam on a particle.
      % For details on usage/arguments see :meth:`forcetorque`.
      %
      % Usage
      %   torque = particle.torque(beam, ...)

      [varargout{1:nargout}] = particle.torqueInternal(beam, varargin{:});
    end

    function varargout = forcetorque(particle, beam, varargin)
      % Calculate force and torque from a beam on a particle.
      %
      % Usage
      %   [force, torque] = particle.forcetorque(beam, ...)
      %
      % Optional named arguments
      %   - position (3xN numeric) -- Positions of the particle to
      %     calculate properties for.
      %     Default: ``[]``.
      %
      %   - rotation (3x3N numeric) -- Orientations of the particle
      %     to calculate properties for.
      %     Default: ``[]``.

      [varargout{1:nargout}] = particle.forcetorqueInternal(beam, varargin{:});
    end
  end

  methods (Hidden)
    function [force, torque] = forcetorqueInternal(particle, varargin)
      % Calculate force and torque on particle in beam
      %
      % The default implementation simply calls ``force`` and ``torque``.

      force = particle.force(varargin{:});
      torque = particle.torque(varargin{:});
    end
  end
end
