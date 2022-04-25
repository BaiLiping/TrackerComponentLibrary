function [xy,cosC]=spher2OrthographicProj(latLonPts,latLonRef,r)
%%SPHER2ORHTOGRAPHICPROJ Given a reference point on a sphere that defines a
%           tangent plane as well as other points on the sphere, find the
%           orthographic projection of those points onto the plane. This is
%           the projection from the points to the plane such that a line
%           connecting the point on the sphere and the point on the plane
%           is normal to the plane.
%
%INPUTS: latLonPoints A 2XN set of points on the reference sphere in
%                     [latitude;longitude] in radians that should be
%                     converted to orthogonally projected coordinates in
%                     the tangent plane.
%           latLonRef The 2X1 [latitude;longitude] reference point for the
%                     orthographic projection.
%                   r The radius of the reference sphere. if this is
%                     omitted or ane mtpy matrix is passed, then
%                     osculatingSpher4LatLon(latLonRef) is used.
%
%OUTPUTS: xy A 2XN set of the points orthographically projected into the
%            local tangent plane at latLonRef. The 3D location of the ith
%            point in the plane is xyPts(1,i)*uEast+xyPts(2,i)*uNorth,
%            where uEast and uNorth are the first two vectors in the output
%            of getENUAxes(latLonRef,false,r,0).
%       cosC This is the 1XN seet of values cosine of the distance between
%            points in latLonPoints and latLonRef when taken on the surface
%            of the unit sphere (distance is radians). If value of this are
%            negative, then the point in question is actually on the other
%            side of the Earth from the reference point, so the inverse
%            projection orthographicProj2Sphere will put it on the wrong
%            side of the Earth.
%
%The conversion is taken from Chapter 20 of [1].
%
%EXAMPLE:
%This example just shows that orthographicProj2Sphere and
%spher2OrthographicProj form a consistent pair. A point on the sphere is
%converted into orthographic coordinates and then it is converted back to
%spherical coordinates. The relative error between the converted-back point
%and the original point is on the order of finite precision limitiations.
% latLonRef=deg2rad([20.756113;-156.010933]);
% latLonPt=deg2rad([19.456233;-154.823617]);
% xy=spher2OrthographicProj(latLonPt,latLonRef);
% latLonPtBack=orthographicProj2Sphere(xy,latLonRef);
% RelErr=max(abs((latLonPt-latLonPtBack)./latLonPt))
%
%REFERENCES:
%[1] J. P. Snyder, "Map projections- a working manual," U.S. Geological
%    Survey, Tech. Rep. 1395, 1987.
%
%May 2021 David F. Crouse, Naval Research Laboratory, Washington D.C.
%(UNCLASSIFIED) DISTRIBUTION STATEMENT A. Approved for public release.

if(nargin<3||isempty(r))
    r=osculatingSpher4LatLon(latLonRef); 
end

%Sine and cosine of the reference latitude.
sinPhi1=sin(latLonRef(1));
cosPhi1=cos(latLonRef(1));
%Reference longitude.
lambda0=latLonRef(2);

cosPhi=cos(latLonPts(1,:));
sinPhi=sin(latLonPts(1,:));
cosPhiDiff=cos(latLonPts(2,:)-lambda0);
%Equations 20-3 and 20-4 in [1].
xy=r*[cosPhi.*sin(latLonPts(2,:)-lambda0);
      (cosPhi1.*sinPhi-sinPhi1.*cosPhi.*cosPhiDiff)];
  
if(nargout>1)
    %Equation 20-5 and 5-3.
    cosC=sinPhi1.*sinPhi+cosPhi1.*cosPhi.*cosPhiDiff;
end
end

%LICENSE:
%
%The source code is in the public domain and not licensed or under
%copyright. The information and software may be used freely by the public.
%As required by 17 U.S.C. 403, third parties producing copyrighted works
%consisting predominantly of the material produced by U.S. government
%agencies must provide notice with such work(s) identifying the U.S.
%Government material incorporated and stating that such material is not
%subject to copyright protection.
%
%Derived works shall not identify themselves in a manner that implies an
%endorsement by or an affiliation with the Naval Research Laboratory.
%
%RECIPIENT BEARS ALL RISK RELATING TO QUALITY AND PERFORMANCE OF THE
%SOFTWARE AND ANY RELATED MATERIALS, AND AGREES TO INDEMNIFY THE NAVAL
%RESEARCH LABORATORY FOR ALL THIRD-PARTY CLAIMS RESULTING FROM THE ACTIONS
%OF RECIPIENT IN THE USE OF THE SOFTWARE.