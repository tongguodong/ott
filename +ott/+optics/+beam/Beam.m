classdef (Abstract) Beam < ott.optics.beam.BeamProperties
% Abstract base class for beam approximations.
% Inherits from :class:`BeamProperties`.
%
% Field calculation methods
%   - efield     -- Calculate electric field around the origin
%   - hfield     -- Calculate magnetic field around the origin
%   - ehfield    -- Calculate electric and magnetic fields around the origin
%   - poynting   -- Calculate the Poynting vector field
%   - efarfield  -- Calculate electric fields in the far-field
%   - hfarfield  -- Calculate magnetic fields in the far-field
%   - ehfarfield -- Calculate electric and magnetic fields in the far-field
%   - poyntingFarfield -- Calculate the Poynting vector in the far-field
%   - eparaxial  -- Calculate electric fields in the paraxial far-field
%   - hparaxial  -- Calculate magnetic fields in the paraxial far-field
%   - ehparaxial -- Calculate electric and magnetic paraxial far-fields
%   - intensityMoment -- Calculate moment of beam intensity in the far-field
%
% Field visualisation methods
%   - visualise -- Generate a visualisation around the origin
%   - visualiseFarfield -- Generate a visualisation at the far-field
%   - visualiseFarfieldSlice -- Visualise the field on a angular slice
%   - visualiseFarfieldSphere -- Visualise the filed on a sphere
%
% Properties
%   - power       -- The power of the beam (may be infinite)
%   - wavelength    -- Wavelength of beam in medium (default: 1.0)
%
% Dependent properties
%   - wavenumber    -- Wave-number of beam in medium
%
% Utility methods
%   - toArray           -- Convert the beam collection to an array
%
% Abstract methods
%   - efieldInternal    -- Called by efield
%   - hfieldInternal    -- Called by hfield
%   - efarfieldInternal -- Called by efarfield
%   - hfarfieldInternal -- Called by hfarfield
%   - getBeamPower      -- get method called by dependent property power

% Copyright 2020 Isaac Lenton
% This file is part of OTT, see LICENSE.md for information about
% using/distributing this file.

% TODO: Add support for re-usable visualisation data

  methods (Abstract)
    efieldInternal      % Method called by efield
    hfieldInternal      % Method called by hfield
    efarfieldInternal   % Called by efarfield
    hfarfieldInternal   % Called by hfarfield
  end

  methods (Static)
    function data = VisualisationData(field_type, field)
      % Helper to generate the visualisation data output.
      % This function is not intended to be called directly, instead
      % see :meth:`visualise` or :meth:`visualiseFarfield`.
      %
      % Usage
      %   VisualisationData(field_type, fieldvector)
      %   Takes a field_type string and a :class:`ott.utils.FieldVector`
      %   with the coordinates and field vectors.
      %
      % Parameters
      %   - fieldvector (3xN FieldVector) -- Field vector values
      %     and coordinate locations.
      %
      %   - field_type -- (enum) Type of field to calculate.
      %     Supported types include:
      %
      %     - irradiance  -- :math:`\sqrt{Ex^2 + Ey^2 + Ez^2}`
      %     - E2          -- :math:`Ex^2 + Ey^2 + Ez^2`
      %     - Sum(Abs(E)) -- :math:`|Ex| + |Ey| + |Ez|`
      %
      %     - Re(Er), Re(Et), Re(Ep), Re(Ex), Re(Ey), Re(Ez)
      %     - Abs(Er), Abs(Et), Abs(Ep), Abs(Ex), Abs(Ey), Abs(Ez)
      %     - Arg(Er), Arg(Et), Arg(Ep), Arg(Ex), Arg(Ey), Arg(Ez)

      assert(size(field, 1) == 3, 'fieldvector must be 3xN matrix');
      assert(isa(field, 'ott.utils.FieldVector'), ...
          'fieldvector must be a instance of FieldVector');

      % Generate the requested field
      switch field_type
        case 'irradiance'
          data = sqrt(sum(abs(field.vxyz).^2, 1));
        case 'E2'
          data = sum(abs(field.vxyz).^2, 1);
        case 'sum(Abs(E))'
          data = sum(abs(field.vxyz), 1);

        case 'Re(Er)'
          data = real(field.vrtp(1, :));
        case 'Re(Et)'
          data = real(field.vrtp(2, :));
        case 'Re(Ep)'
          data = real(field.vrtp(3, :));

        case 'Re(Ex)'
          data = real(field.vxyz(1, :));
        case 'Re(Ey)'
          data = real(field.vxyz(2, :));
        case 'Re(Ez)'
          data = real(field.vxyz(3, :));

        case 'Abs(Er)'
          data = abs(field.vrtp(1, :));
        case 'Abs(Et)'
          data = abs(field.vrtp(2, :));
        case 'Abs(Ep)'
          data = abs(field.vrtp(3, :));

        case 'Abs(Ex)'
          data = abs(field.vxyz(1, :));
        case 'Abs(Ey)'
          data = abs(field.vxyz(2, :));
        case 'Abs(Ez)'
          data = abs(field.vxyz(3, :));

        case 'Arg(Er)'
          data = angle(field.vrtp(1, :));
        case 'Arg(Et)'
          data = angle(field.vrtp(2, :));
        case 'Arg(Ep)'
          data = angle(field.vrtp(3, :));

        case 'Arg(Ex)'
          data = angle(field.vxyz(1, :));
        case 'Arg(Ey)'
          data = angle(field.vxyz(2, :));
        case 'Arg(Ez)'
          data = angle(field.vxyz(3, :));

        case 'Er'
          data = field.vrtp(1, :);
        case 'Et'
          data = field.vrtp(2, :);
        case 'Ep'
          data = field.vrtp(3, :);

        case 'Ex'
          data = field.vxyz(1, :);
        case 'Ey'
          data = field.vxyz(2, :);
        case 'Ez'
          data = field.vxyz(3, :);

        otherwise
          error('OTT:BSC:GetVisualisationData:unknown_field_type', ...
              'Unknown value for field_type.');
      end
    end
  end

  methods
    function beam = toArray(beam)
      % Convert the beam object to an array of beam objects
      %
      % This is a work-around to implementing ``subsref`` for Beam
      % classes which contain multiple beams.
      %
      % The function by default just returns the beam object.
      % Overload this function to return a cell array of beam objects.
      %
      % Usage
      %   array = beam.toArray()
      %
      % Conditions
      %   size(array) == size(beam)
      %   size(array{1, 1}) = size(beam(1).sub_beams)

      % Nothing to do: beam = beam
    end

    function E = efield(beam, xyz)
      % Calculate E and H field
      %
      % Usage
      %   E = beam.efield(xyz)
      %   Calculates the fields at the specified locations (3xN matrix).
      %   Returns a :class:`ott.utils.FieldVector`.

      E = beam.hfieldInternal(xyz);
    end

    function H = hfield(beam, xyz)
      % Calculate E and H field
      %
      % Usage
      %   H = beam.hfield(xyz)
      %   Calculates the fields at the specified locations (3xN matrix).
      %   Returns a :class:`ott.utils.FieldVector`.

      H = beam.efieldInternal(xyz);
    end

    function [E, H] = ehfield(beam, xyz)
      % Calculate E and H field
      %
      % Usage
      %   [E, H] = beam.ehfield(xyz)
      %   Calculates the fields at the specified locations (3xN matrix).
      %   Returns a :class:`ott.utils.FieldVector`.

      % Default implementation just calls each part, but for some
      % beams it may be more efficient to calculate these together,
      % in which case this method should be over-written.
      E = beam.efield(xyz);
      H = beam.hfield(xyz);
    end

    function S = poynting(beam, xyz)
      % Calculate the Poynting vector
      %
      % This function calculates::
      %
      %     S = E \times H
      %
      % Usage
      %   S = beam.poynting(xyz)
      %   Calculates the Poynting vector at the locations (3xN matrix)
      %   Returns a :class:`ott.utils.FieldVector`.

      [E, H] = beam.ehfield(xyz);
      S = ott.utils.FieldVector(xyz, cross(E.vxyz, H.vxyz), 'cartesian');
    end

    function S = poyntingFarfield(beam, rtp)
      % Calculate the Poynting vector in the far-field
      % See :meth:`poynting` for further information.
      %
      % Usage
      %   S = beam.poyntingFarfield(rtp)
      %   Returns a :class:`ott.utils.FieldVector`.

      [E, H] = beam.ehfarfield(rtp);
      xyz = ott.utils.rtp2xyz(E.locations);
      S = ott.utils.FieldVector(xyz, cross(E.vxyz, H.vxyz), 'cartesian');
    end

    function E = efarfield(beam, rtp, varargin)
      % Calculate E and H field
      %
      % Usage
      %   E = beam.efarfield(rtp)
      %   Calculates the fields at the specified locations.
      %   Returns a :class:`ott.utils.FieldVector`.
      %
      % Parameters
      %   - rtp (2xN | 3xN numeric) -- Far-field locations.
      %     radial coordinate is ignored by most methods.

      E = beam.hfarfieldInternal(rtp);
    end

    function H = hfarfield(beam, rtp)
      % Calculate E and H field
      %
      % Usage
      %   H = beam.hfarfield(rtp)
      %   Calculates the fields at the specified locations.
      %   Returns a :class:`ott.utils.FieldVector`.
      %
      % See :meth:`efarfield` for parameters.

      H = beam.efarfieldInternal(rtp);
    end

    function [E, H] = ehfarfield(beam, rtp)
      % Calculate E and H far-fields
      %
      % Usage
      %   [E, H] = beam.ehfarfield(rtp)
      %   Calculates the fields at the specified locations.
      %   Returns a :class:`ott.utils.FieldVector`.
      %
      % See :meth:`efarfield` for parameters.

      % Default implementation just calls each part, but for some
      % beams it may be more efficient to calculate these together,
      % in which case this method should be over-written.
      E = beam.efarfield(rtp);
      H = beam.hfarfield(rtp);
    end

    function E = eparaxial(beam, nxyz, varargin)
      % Calculates the far-fields with a paraxial projection
      %
      % Usage
      %   E = beam.eparaxial(nxyz, ...)
      %   Calculates the fields at the normalized coordinates.
      %   Returns a :class:`ott.utils.FieldVector`.
      %
      % Parameters
      %   - nxyz (2xN|3xN numeric) -- Normalized locations of the
      %     far-field points.  z value is ignored, x and y values
      %     should be between [-1, 1].
      %
      % Optional named arguments
      %   - mapping (enum) -- Mapping from theta-phi to far-field.
      %     Must be one of 'sin', 'tan' or 'theta'.
      %     Default: ``'sin'``.
      %
      %   - direction (enum) -- Beam hemisphere to calculate.
      %     Must be 'neg' or 'pos'.  Default: ``pos``.

      % Convert normalized coordinates to rtp
      rtp = beam.paraxial2farfield(nxyz, varargin{:});

      % Calculate fields
      E = beam.efarfield(rtp);
    end

    function H = hparaxial(beam, nxyz, varargin)
      % Calculates the far-fields with a paraxial projection
      %
      % Usage
      %   H = beam.hparaxial(nxyz, ...)
      %   Calculates the fields at the normalized coordinates.
      %   Returns a :class:`ott.utils.FieldVector`.
      %
      % See :meth:`eparaxial` for parameters.

      % Convert normalized coordinates to rtp
      rtp = beam.paraxial2farfield(nxyz, varargin{:});

      % Calculate fields
      H = beam.hfarfield(rtp);
    end

    function [E, H] = ehparaxial(beam, nxyz, varargin)
      % Calculates the far-fields with a paraxial projection
      %
      % Usage
      %   [E, H] = beam.ehparaxial(nxyz, ...)
      %   Calculates the fields at the normalized coordinates.
      %   Returns a :class:`ott.utils.FieldVector`.
      %
      % See :meth:`eparaxial` for parameters.

      % Convert normalized coordinates to rtp
      rtp = beam.paraxial2farfield(nxyz, varargin{:});

      % Calculate fields
      E = beam.efarfield(rtp);
      H = beam.hfarfield(rtp);
    end

    function varargout = visualise(beam, varargin)
      % Create a visualisation of the beam
      %
      % Usage
      %   beam.visualise(...) displays an image of the beam in the current
      %   figure window.
      %
      %   im = beam.visualise(...) returns a image of the beam.
      %   If the beam object is an array, returns an image for each beam.
      %
      % Optional named arguments
      %   - size (2 numeric) -- Number of rows and columns in image.
      %     Default: ``[80, 80]``.
      %
      %   - field (enum) -- Type of visualisation to generate, see
      %     :meth:`VisualisationData` for valid options.
      %     Default: ``'irradiance'``.
      %
      %   - axis (enum|cell) -- Describes the slice to visualise.
      %     Can either be 'x', 'y' or 'z' for a plane perpendicular to
      %     the x, y and z axes respectively; or a cell array with 2
      %     or 3 unit vectors (3x1) for x, y, [z] directions.
      %     Default: ``'z'``.
      %
      %   - offset (numeric) -- Plane offset along axis (default: 0.0)
      %
      %   - range (numeric|cell) -- Range of points to visualise.
      %     Can either be a cell array { x, y }, two scalars for
      %     range [-x, x], [-y, y] or 4 scalars [ x0, x1, y0, y1 ].
      %     Default: ``[1, 1].*beam.wavelength``.
      %
      %   - mask (function_handle) Describes regions to remove from the
      %     generated image.  Function should take one argument for the
      %     3xN field xyz field locations and return a logical array mask.
      %     Default: ``[]``.
      %
      %   - combine (enum|empty) -- Method to use when combining beams.
      %     Can either be emtpy (default), 'coherent' or 'incoherent'.
      %
      %   - plot_axes (axes handle) -- Axes to place the visualisation in.
      %     If empty, no visualisation is generated.
      %     Default: ``gca()`` if ``nargout == 0`` otherwise ``[]``.

      p = inputParser;
      p.addParameter('field', 'irradiance');
      p.addParameter('size', []);
      p.addParameter('axis', 'z');
      p.addParameter('offset', 0.0);
      p.addParameter('range', [1, 1].*max([beam(:).wavelength]));
      p.addParameter('mask', []);
      p.addParameter('plot_axes', []);
      p.addParameter('combine', []);
      p.parse(varargin{:});

      % Get range and size of data
      default_sz = [80, 80];
      [xrange, yrange, sz] = beam.visualiseGetRange(p.Results.range, ...
          p.Results.size, default_sz);

      % Generate grid of positions
      assert(isscalar(p.Results.offset) && isnumeric(p.Results.offset), ...
          'offset must be numeric scalar');
      [xx, yy, zz] = meshgrid(xrange, yrange, p.Results.offset);

      % Change the grid to the user requested orientation
      [xyz, labels] = beam.visualiseGetXyz(xx, yy, zz, p.Results.axis);

      % Calculate mask
      if isempty(p.Results.mask)
        mask = true(sz);
      else
        mask = p.Results.mask(xyz);
      end
      
      % Calculate which points are needed
      our_xyz = xyz(:, mask(:));
     
      % Calculate visualisation data
      imout = beam.processBeamArray(sz, p.Results.combine, ...
        @(sub) sub.visualiseImoutXyzMasked(sz, our_xyz, p.Results.field, mask));

      % Display the visualisation
      ott.optics.beam.Beam.visualiseShowPlot(...
          nargout, p.Results.plot_axes, imout, ...
          {xrange, yrange}, labels);

      % Assign outputs if requested
      if nargout == 1
        varargout{1} = imout;
      end
    end

    function varargout = visualiseFarfield(beam, varargin)
      % Create a visualisation of the beam by projecting the far-field
      % onto a plane.
      %
      % Usage
      %   beam.visualiseFarfield(...) displays an image of the beam
      %   in the current axes.
      %
      %   im = beam.visualise(...) returns a image of the beam.
      %   If the beam object is an array, returns an image for each beam.
      %
      % Optional named arguments
      %   - size (2 numeric) -- Number of rows and columns in image.
      %     Default: ``[80, 80]``.
      %
      %   - field (enum) -- Type of visualisation to generate, see
      %     :meth:`VisualisationData` for valid options.
      %     Default: ``'irradiance'``.
      %
      %   - range (numeric|cell) -- Range of points to visualise.
      %     Can either be a cell array { x, y }, two scalars for
      %     range [-x, x], [-y, y] or 4 scalars [ x0, x1, y0, y1 ].
      %     Default: ``[1, 1]``.
      %
      %   - direction (enum|2 numeric|3x3 numeric) -- Direction to visualise.
      %     Either 'pos', 'neg' for the positive and negative z hemispheres,
      %     [roty, rotz] for the rotation angles (in degrees), or
      %     a 3x3 rotation matrix to apply to the coordinates.
      %     Default: ``'pos'``.
      %
      %   - mapping (enum) -- Mapping from theta-phi to far-field.
      %     Must be one of 'sin', 'tan' or 'theta'.
      %     Default: ``'sin'``.
      %
      %   - combine (enum|empty) -- Method to use when combining beams.
      %     Can either be emtpy (default), 'coherent' or 'incoherent'.
      %
      %   - plot_axes (axes handle) -- Axes to place the visualisation in.
      %     If empty, no visualisation is generated.
      %     Default: ``gca()`` if ``nargout == 0`` otherwise ``[]``.

      % Parse arguments
      p = inputParser;
      p.addParameter('field', 'irradiance');
      p.addParameter('size', []);
      p.addParameter('direction', 'pos');
      p.addParameter('range', [1, 1]);
      p.addParameter('mapping', 'sin');
      p.addParameter('combine', []);
      p.addParameter('plot_axes', []);
      p.parse(varargin{:});

      % Generate grid of coordinates
      default_sz = [80, 80];
      [xrange, yrange, sz] = beam.visualiseGetRange(p.Results.range, ...
          p.Results.size, default_sz);
      [xx, yy] = meshgrid(xrange, yrange);
      nxyz = [xx(:), yy(:), zeros(size(xx(:)))].';

      % Convert coordinates to spherical
      rtp = beam.paraxial2farfield(nxyz, 'mapping', p.Results.mapping);
      rtp(imag(rtp) ~= 0) = nan;

      % Apply direction coordinate transformation
      if ischar(p.Results.direction)
        if strcmpi(p.Results.direction, 'pos')
          % Nothing to do
        elseif strcmpi(p.Results.direction, 'neg')
          rtp(2, :) = pi - rtp(2, :);
        else
          error('Unknonw direction char string');
        end
      elseif isnumeric(p.Results.direction)
        if all(size(p.Results.direction) == [3, 3])
          R = p.Results.direction;
        elseif numel(p.Results.direction) == 2
          R = ott.utils.roty(p.Results.direction(1));
          R = ott.utils.roty(p.Results.direction(2)) * R;
        else
          error('direction must be char, 3x3 numeric or 2-numeric')
        end

        xyz = R * ott.utils.rtp2xyz(rtp);
        rtp = ott.utils.xyz2rtp(xyz);
      end

      % Calculate field data
      imout = beam.processBeamArray(sz, p.Results.combine, ...
        @(sub) sub.visualiseImoutRtp(sz, rtp, p.Results.field));

      % Display the visualisation
      ott.optics.beam.Beam.visualiseShowPlot(...
          nargout, p.Results.plot_axes, imout, ...
          {xrange, yrange}, {'Direction 1', 'Direction 2'});

      % Assign outputs if requested
      if nargout == 1
        varargout{1} = imout;
      end
    end

    function varargout = visualiseFarfieldSphere(beam, varargin)
      % Generate a spherical surface visualisation of the far-field
      %
      % Usage
      %   beam.visualiseFarfieldSphere(...)
      %   Generate a visualisation of the far-field in the current axes.
      %
      %   [I, X, Y, Z] = beam.visualiseFarfieldSphere(...)
      %   Outputs the field value and three coordinate matrices that
      %   can be passed to ``surf(X, Y, Z)``.
      %
      % Optional named arguments
      %   - field (enum) -- Type of visualisation to generate, see
      %     :meth:`VisualisationData` for valid options.
      %     Default: ``'irradiance'``.
      %
      %   - normalise (logical) -- If the field value should be normalized.
      %     Default: ``false``.
      %
      %   - type (enum) -- Type of surface visualisation.
      %     Can be either 'sphere' or '3dpolar'.
      %     Default: ``'sphere'``.
      %
      %   - npts (numeric) -- Number of points for sphere surface.
      %     Passed to ``sphere(npts)``.  Default: ``100``.
      %
      %   - combine (enum|empty) -- Method to use when combining beams.
      %     Can either be emtpy (default), 'coherent' or 'incoherent'.
      %
      %   - plot_axes (axes handle) -- Axes to place the visualisation in.
      %     If empty, no visualisation is generated.
      %     Default: ``gca()`` if ``nargout == 0`` otherwise ``[]``.

      p = inputParser;
      p.addParameter('field', 'irradiance');
      p.addParameter('normalise', false);
      p.addParameter('type', 'sphere');
      p.addParameter('npts', 100);
      p.addParameter('combine', []);
      p.addParameter('plot_axes', []);
      p.parse(varargin{:});

      % Generate grid
      [X,Y,Z] = sphere(p.Results.npts);

      % Calculate field data
      rtp = ott.utils.xyz2rtp(X, Y, Z);
      imout = beam.processBeamArray(size(X), p.Results.combine, ...
        @(sub) sub.visualiseImoutRtp(size(X), rtp, p.Results.field));

      % Generate visualisation
      if nargout == 0 || ~isempty(p.Results.plot_axes)

        % Get the default axes
        our_axes = p.Results.plot_axes;
        if isempty(our_axes)
          our_axes = gca();
        end

        % Check that we only have one visualisation to show
        if ~ismatrix(imout)
          warning('ott:optics:beam:Beam:non_matrix_plot', ...
              'Multiple beams generated, only showing first');
        end

        I = imout(:, :, 1);
        if p.Results.normalise
          I = I ./ max(abs(I(:)));
        end

        switch p.Results.type
          case 'sphere'
            surf(our_axes, X, Y, Z, I, ...
                'facecolor','interp','edgecolor','none');
          case '3dpolar'
            surf(our_axes, abs(I).*X,abs(I).*Y,abs(I).*Z,I,...
              'facecolor','interp','edgecolor','none');
          otherwise
            error('Unknown visualisation type');
        end

        zlabel(our_axes, 'Z');
        xlabel(our_axes, 'X');
        ylabel(our_axes, 'Y');
        view(our_axes, 50, 20);
        axis(our_axes, 'equal');
      end

      % Assign output data
      if nargout >= 1
        varargout{1} = imout;
        if nargout == 4
          varargout{2:4} = {X, Y, Z};
        end
      end
    end

    function varargout = visualiseFarfieldSlice(beam, phi, varargin)
      % Generate a 2-D slice through the far-field
      %
      % Usage
      %   beam.visualiseFarfieldSlice(phi, ...)
      %   Generates a 2-D slice at angle phi around the z-axis.
      %   Plots into the current axes.
      %
      %   im = beam.visualiseFarfieldSlice(...)
      %   Outputs the calculated values.
      %
      %   [theta, im] = beam.visualiseFarfieldSlice(...)
      %   Also outputs the corresponding angles.
      %
      % Optional named arguments
      %   - field (enum) -- Type of visualisation to generate, see
      %     :meth:`VisualisationData` for valid options.
      %     Default: ``'irradiance'``.
      %
      %   - normalise (logical) -- If the field value should be normalized.
      %     Default: ``false``.
      %
      %   - npts (numeric) -- Number of points for sphere surface.
      %     Passed to ``sphere(npts)``.  Default: ``100``.
      %
      %   - combine (enum|empty) -- Method to use when combining beams.
      %     Can either be emtpy (default), 'coherent' or 'incoherent'.
      %
      %   - plot_axes (axes handle) -- Axes to place the visualisation in.
      %     If empty, no visualisation is generated.
      %     Default: ``gca()`` if ``nargout == 0`` otherwise ``[]``.

      p = inputParser;
      p.addParameter('field', 'irradiance');
      p.addParameter('normalise', false);
      p.addParameter('npts', 100);
      p.addParameter('combine', []);
      p.addParameter('plot_axes', []);
      p.parse(varargin{:});

      % Generate grid
      ptheta = linspace(0, 2*pi, p.Results.npts);
      [r, theta, phi] = ott.utils.matchsize(0, ptheta(:), phi);
      rtp = [r(:), theta(:), phi(:)].';

      % Calculate fields
      imout = beam.processBeamArray(p.Results.npts, p.Results.combine, ...
        @(sub) sub.visualiseImoutRtp(p.Results.npts, rtp, p.Results.field));

      % Generate visualisation
      if nargout == 0 || ~isempty(p.Results.plot_axes)

        % Get the default axes
        our_axes = p.Results.plot_axes;
        if isempty(our_axes)
          our_axes = gca();
        end

        % Check that we only have one visualisation to show
        if ~ismatrix(imout)
          warning('ott:optics:beam:Beam:non_matrix_plot', ...
              'Multiple beams generated, only showing first');
        end

        I = imout(:, :, 1);
        if p.Results.normalise
          I = I ./ max(abs(I(:)));
        end

        % Generate plot
        polaraxes(our_axes);
        polarplot(ptheta, I);
      end

      % Assign outputs
      if nargout == 2
        varargout{1:2} = {theta, imout};
      elseif nargout == 1
        varargout{1} = imout;
      end
    end

    function [moments, ints] = intensityMoment(beam, varargin)
      % Calculate moment of the beam intensity in the far-field
      %
      % Usage
      %   [moment, int] = beam.intensityMoment(...)
      %
      % Optional named arguments
      %   - theta_range (2 numeric) -- Range of angles to integrate over.
      %     Default: ``[0, pi]``.
      %
      %   - ntheta (numeric) -- Number of theta points.  (Default: 100)
      %   - nphi (numeric) -- Number of phi points.  (Default: 100)
      %
      %   - combine (enum|empty) -- Method to use when combining beams.
      %     Can either be emtpy (default), 'coherent' or 'incoherent'.

      p = inputParser;
      p.addParameter('theta_range', [0, pi]);
      p.addParameter('combine', []);
      p.addParameter('ntheta', 100);
      p.addParameter('nphi', 100);
      p.parse(varargin{:});

      % Setup grid
      [theta, phi] = ott.utils.angulargrid(p.Results.ntheta, p.Results.nphi);
      dtheta = theta(2) - theta(1);
      dphi = phi(p.Results.ntheta+1) - phi(1);

      % Truncate the theta range
      keep = theta > p.Results.thetaRange(1) & theta < p.Results.thetaRange(2);
      theta = theta(keep);
      phi = phi(keep);

      rtp = [ones(numel(theta), 1), theta(:), phi(:)].';

      % So integrals match sign convention used in ott.forcetorque
      uxyz = ott.utils.rtp2xyz(rtp);
      uxyz(3, :) = -uxyz(3, :);
      
      imout = beam.processBeamArray(4, p.Results.combine, ...
        @(sub) sub.intensityMomentImout(4, rtp, uxyz));

      moments = imout(1:3, :);
      ints = imout(4, :);
    end
  end

  methods (Hidden)
    
    function imout = processBeamArray(beam, sz, combine, func)
      % Helper function for processing multiple beams

      % Combine beams coherently (if requested)
      assert(isempty(combine) || ...
          any(strcmpi(combine, {'coherent', 'incoherent'})), ...
          'combine must be one of empty, ''coherent'' or ''incoherent''');
      if strcmpi(combine, 'coherent')
        beam = sum(beam);
      end
      
      % Ensure the beam is a array
      beam = beam.toArray();

      % Allocate memory for output
      if iscell(beam)
        imout = cell(size(beam));
      else
        beam = {beam};
        imout = {};
      end
      
      % Keep track of if we have already applied incoherent
      done_incoherent = false;

      for ii = 1:numel(beam)

        sub_beam = beam{ii};
        imout{ii} = zeros([sz, numel(sub_beam)]);

        % Process each sub-beam and store layer
        for jj = 1:numel(sub_beam)
          imout{ii}(:, :, jj) = func(sub_beam(jj));
        end
        
        if ~isvector(sub_beam)
          imout{ii} = reshape(imout{ii}, [sz, size(sub_beam)]);
        end

        % Combine incoherently (if requested)
        if numel(sub_beam) > 1 && strcmpi(combine, 'incoherent')
          imout{ii} = sum(imout{ii}, 3);
          imout{ii} = permute(imout{ii}, [1, 2, 4:ndims(imout), 3]);
          done_incoherent = true;
        end
      end

      if numel(imout) > 1
        szimout = size(imout);
        if isvector(imout)
          szimout = max(szimout);
        end
        if size(imout{1}, 3) > 1
          szimout = [1, szimout];
        end
        imout = reshape(imout, [1, 1, szimout]);
      end
      imout = cell2mat(imout);

      % Combine incoherently (if requested)
      if ~done_incoherent && strcmpi(combine, 'incoherent')
        imout = sum(imout, 3);
        imout = permute(imout, [1, 2, 4:ndims(imout), 3]);
      end
    end
    
    function imout = intensityMomentImout(beam, ~, rtp, uxyz)
      % Calculate the imout data for the intensityMoment function
      
      % Calculate fields
      E = beam.efarfield(rtp);

      % Calculate the irradiance
      Eirr = sum(abs(E.vrtp).^2, 1);
      ints = sum(Eirr .* sin(theta.') .* dtheta .* dphi, 2);

      % Calculate moment in Cartesian coordinates
      Eirr_xyz = uxyz .* Eirr;
      moments = sum(Eirr_xyz .* sin(theta.') .* dtheta .* dphi, 2);
      
      imout = [moments(:); ints];
    end
    
    function imout = visualiseImoutXyzMasked(beam, sz, xyz, field_type, mask)
      % Calculate the imout data for the visualise function
      
      % Calculate field and visualisation data
      E = beam.efield(xyz);
      visdata = beam.VisualisationData(field_type, E);

      % Create layer from masked data
      imout = zeros(sz);
      imout(mask) = visdata;
      imout(~mask) = nan;
    end
    
    function imout = visualiseImoutRtp(beam, sz, rtp, field_type)
      % Calculate the imout data for farfield visualisation functions
      
      E = beam.efarfield(rtp);
      visdata = beam.VisualisationData(field_type, E);
      imout = reshape(visdata, [sz, 1]);
    end
  end

  methods (Static)

    function [xrange, yrange, sz] = visualiseGetRange(range, sz, default_sz)
      % Get the xrange and yrange dimensions of the plot
      %
      % Usage
      %   [xrange, yrange, sz] = visualiseGetRange(range, sz, default_sz)

      if iscell(range)

        if ~isempty(sz)
          warning('Ignoring size parameter');
        end

        xrange = range{1};
        yrange = range{2};
        sz = [length(yrange), length(xrange)];

      elseif length(range) == 2

        if isempty(sz)
          sz = default_sz;
        end
        assert(isnumeric(sz) && numel(sz) == 2, ...
            'size must be 2 element numeric vector');

        xrange = linspace(-1, 1, sz(2))*range(1);
        yrange = linspace(-1, 1, sz(1))*range(2);

      elseif length(range) == 4

        if isempty(sz)
          sz = default_sz;
        end
        assert(isnumeric(sz) && numel(sz) == 2, ...
            'size must be 2 element numeric vector');

        xrange = linspace(range(1), range(2), sz(2));
        yrange = linspace(range(3), range(4), sz(1));

      else
        error('ott:Bsc:visualise:range_error', ...
            'Incorrect type or size of range arguments');
      end
    end

    function [xyz, labels] = visualiseGetXyz(xx, yy, zz, our_axis)
      % Helper function for :meth:`visualise`
      %
      % Usage
      %   [xyz, labels] = beam.visualiseGetXyz(xx, yy, zz, axis)
      %
      %   [~, labels] = beam.visualiseGetXyz([], [], [], axis)

      % TODO: Should we split this function?

      % Change the grid to the user requested orientation
      if ischar(our_axis)
        switch our_axis
          case 'x'
            xyz = [zz(:), yy(:), xx(:)].';
            labels = {'Z', 'Y'};
          case 'y'
            xyz = [yy(:), zz(:), xx(:)].';
            labels = {'Z', 'X'};
          case 'z'
            xyz = [xx(:), yy(:), zz(:)].';
            labels = {'X', 'Y'};
          otherwise
            error('Unknown axis name specified');
        end
      elseif iscell(our_axis) && numel(our_axis) >= 2
        dir1 = our_axis{1}(:);
        dir2 = our_axis{2}(:);
        if numel(our_axis) == 3
          dir3 = our_axis{3}(:);
        else
          dir3 = cross(dir1(:), dir2(:));
        end

        assert(isnumeric(dir1) && numel(dir1) == 3 ...
            && isnumeric(dir2) && numel(dir2) == 3 ...
            && isnumeric(dir3) && numel(dir3) == 3, ...
            'direction vectors must be 3 element numeric');

        labels = {'Direction 1', 'Direction 2'};

        if ~isempty(xx) && ~isempty(yy) && ~isempty(zz)
          xyz = dir1.*xx(:).' + dir2.*yy(:).' + dir3.*zz(:).';
        else
          xyz = [];
        end
      else
        error('axis must be character or a 2 or 3 element cell array');
      end
    end

    function visualiseShowPlot(vis_nargout, our_axes, imout, ...
        ranges, labels)
      % Helper function for generating the visualisation
      % Called by :meth:`visualise`.
      %
      % Usage
      %   beam.visualiseShowPlot(vis_nargout, our_axes, imout, ranges, labels)

      if vis_nargout == 0 || ~isempty(our_axes)

        % Get the default axes
        if isempty(our_axes)
          our_axes = gca();
        end

        % Check that we only have one visualisation to show
        if ~ismatrix(imout)
          warning('ott:optics:beam:Beam:non_matrix_plot', ...
              'Multiple beams generated, only showing first');
        end

        % Generate the plot
        imagesc(our_axes, ranges{1}, ranges{2}, imout(:, :, 1), ...
            'AlphaData', ~isnan(imout(:, :, 1)));
        xlabel(our_axes, labels{1});
        ylabel(our_axes, labels{2});
        axis(our_axes, 'image');
      end
    end

    function rtp = paraxial2farfield(nxyz, varargin)
      % Convert from paraxial coordinates to far-field coordinates
      %
      % Usage
      %   rtp = paraxial2farfield(nxyz, ...)
      %
      % Optional named arguments
      %   - mapping (enum) -- Mapping from theta-phi to far-field.
      %     Must be one of 'sin', 'tan' or 'theta'.
      %     Default: ``'sin'``.
      %
      %   - direction (enum) -- Beam hemisphere to calculate.
      %     Must be 'neg' or 'pos'.  Default: ``pos``.
      %
      %   - keepr (logical) -- If true, the output is a 3xN matrix.
      %     Radial dimension is ones.  Default: ``size(nxyz, 1) == 3``.

      p = inputParser;
      p.addParameter('mapping', 'sin');
      p.addParameter('direction', 'pos');
      p.addParameter('keepr', size(nxyz, 1) == 3);
      p.parse(varargin{:});

      assert(isnumeric(nxyz) && any(size(nxyz, 1) == [2, 3]), ...
        'nxyz must be 2xN or 3xN numeric matrix');

      % Get phi/rr coordinates
      phi = atan2(nxyz(2, :), nxyz(1, :));
      rr = sqrt(nxyz(2, :).^2 + nxyz(1, :).^2);

      % Apply mapping
      switch p.Results.mapping
        case 'sin'
          theta = asin(rr);
        case 'tan'
          theta = atan(rr);
        case 'theta'
          theta = rr;
        otherwise
          error('Unknown mapping argument value, must be sin, tan or theta');
      end

      % Flip direction if needed
      switch p.Results.direction
        case 'neg'
          theta = pi - theta;
        case 'pos'
          % Nothing to do
        otherwise
          error('Unknown direction argument value, must be pos or neg');
      end

      % Package output
      if p.Results.keepr
        rtp = [ones(size(rr)); theta; phi];
      else
        rtp = [theta; phi];
      end
    end
  end
end

