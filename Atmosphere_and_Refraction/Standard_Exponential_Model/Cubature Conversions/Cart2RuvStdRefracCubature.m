function [zRuv,RRuv]=Cart2RuvStdRefracCubature(zC,SR,useHalfRange,zTx,zRx,M,Ns,xi,w,ce,ellipsOpts)
%%CART2RUVSTDREFRACCUBATURE Use cubature integration to approximate the
%                   moments of measurements converted from Cartesian
%                   coordinates into refraction-corrupted bistatic r-u-v
%                   coordinates using a standard exponential atmospheric
%                   model. For a two-way monostatic conversion, set
%                   zTx=[0;0;0]; to make the transmitter and receiver
%                   collocated.
%
%INPUTS: zC A 3XnumMeas matrix of Cartesian points in global [x;y;z]
%           Cartesian coordinates that are to be converted.
%        SR The 3X3XnumMeas lower-triangular square root of the
%           measurement covariance matrices for each measurement. If all of
%           the matrices are the same, then this can just be a single 3X3
%           matrix.
% useHalfRange  A boolean value specifying whether the bistatic range value
%           has been divided by two. This normally comes up when
%           operating in monostatic mode, so that the range reported is a
%           one-way range. The default if this parameter is not provided
%           is false.
%       zTx The 3X1 [x;y;z] location vector of the transmitter in global
%           Cartesian coordinates. If this parameter is omitted or an
%           empty matrix is passed, then the receiver is placed at the
%           origin.
%       zRx The 3X1 [x;y;z] location vector of the receiver in global
%           Cartesian coordinates. If this parameter is omitted or an
%           empty matrix is passed, then the receiver is placed at the
%           origin.
%         M A 3X3 rotation matrix to go from the alignment of the global
%           coordinate system to the local alignment of the receiver. The z
%           vector of the local coordinate system of the receiver is the
%           pointing direction of the receiver. If this matrix is omitted,
%           then the identity matrix is used.
%        Ns The atmospheric refractivity reduced to the WGS-84 reference
%           ellipsoid. Note that the refractivity is (n-1)*1e6, where n is
%           the index of refraction. The function reduceStdRefrac2Spher can
%           be used to reduce a refractivity to the ellipsoidal surface.
%           This function does not allowe different refractivities to be
%           used as the transmitter and receiver. If this parameter is
%           omitted or an empty matrix is passed, a default value of 313 is
%           used.
%        xi A 3 X numCubaturePoints matrix of cubature points for the
%           numeric integration. If this and the next parameter are omitted
%           or empty matrices are passed, then fifthOrderCubPoints is used
%           to generate cubature points.
%         w A numCubaturePoints X 1 vector of the weights associated with
%           the cubature points.
%        ce The optional decay constant of the exponential model. The
%           refractivity N at height h is N=Ns*exp(-ce*(h-h0)) where h0 is
%           the reference height (in this function, the height of the
%           reference ellipsoid surface is used). ce is related to the
%           change in refractivity at an elevation of 1km based on the
%           refractivity at sea level as
%           ce=log(Ns/(Ns+DeltaN))/1000;%Units of inverse meters.
%           where the change in refractivity for a change in elevation of
%           1km is DeltaN=-multConst*exp(expConst*Ns); In [1], standard
%           values for the two constants are expConst=0.005577; and
%           multConst=7.32; If ce is omitted or an empty matrix is passed,
%           the value based on the standard model is used.
% ellipOpts Optioanlly, a structure that contains elements changing the
%           reference ellipsoid used. Possible entries are a for the
%           semi-major axis and f for the flattening factor. If this
%           parameter is omitted or an empty matrix is passed, then
%           a=Constants.WGS84SemiMajorAxis and f=Constants.WGS84Flattening.
%
%OUTPUTS: zRuv The approximate means of the PDF of the measurements
%              in refraction-corrupted bistatic [r;u;v] coordinates. This
%              is a 3XnumMeas matrix.
%         RRuv The approximate 3X3XnumMeas covariance matrices of the
%              PDF of the refraction-corrupted bistatic [r;u;v] converted
%              measurements. This is a 3X3XnumMeas hypermatrix.
%
%The basic cubature conversion approach is detailed in [1] and [2]. The
%standard exponential measurement model is from [3] and the model is
%discussed in more detail in the comments to Cart2RuvStdRefrac.
%
%REFERENCES:
%[1] D. F. Crouse, "Basic tracking using 3D monostatic and bistatic
%    measurements in refractive environments," IEEE Aerospace and
%    Electronic Systems Magazine, vol. 29, no. 8, Part II, pp. 54-75, Aug.
%    2014.
%[2] David F. Crouse , "Basic tracking using nonlinear 3D monostatic and
%    bistatic measurements," IEEE Aerospace and Electronic Systems 
%    Magazine, vol. 29, no. 8, Part II, pp. 4-53, Aug. 2014.
%[3] B. R. Bean and G. D. Thayer, CRPL Exponential Reference Atmosphere.
%    Washington, D.C.: U. S. Department of Commerce, National Bureau of
%    Standards, Oct. 1959. [Online]. Available:
%    http://digicoll.manoa.hawaii.edu/techreports/PDF/NBS4.pdf
%
%June 2016 David F. Crouse, Naval Research Laboratory, Washington D.C.
%(UNCLASSIFIED) DISTRIBUTION STATEMENT A. Approved for public release.

if(nargin<3||isempty(useHalfRange))
    useHalfRange=false;
end

if(nargin<4||isempty(zTx))
   zTx=zeros(3,1); 
end

if(nargin<5||isempty(zRx))
   zRx=zeros(3,1); 
end

if(nargin<6||isempty(M))
   M=eye(3,3); 
end

if(nargin<7||isempty(Ns))
   Ns=313;
end

if(nargin<8||isempty(xi))
    [xi,w]=fifthOrderCubPoints(3);
end

if(nargin<10||isempty(ce))
    expConst=0.005577;
    multConst=7.32;

    %The change in refractivity at an elevation of 1km based on the
    %refractivity on the surface of the Earth.
    DeltaN=-multConst*exp(expConst*Ns);
    ce=log(Ns/(Ns+DeltaN))/1000;%Units of inverse meters.
end

if(nargin<11)
    %Use the defaults in the function Cart2RuvStdRefrac.
    ellipsOpts=[];
end

numMeas=size(zC,2);

if(size(SR,3)==1)
    SR=repmat(SR,[1,1,numMeas]);
end

zRuv=zeros(3,numMeas);
RRuv=zeros(3,3,numMeas);
for curMeas=1:numMeas
    %Transform the cubature points to match the given Gaussian.
    cubPoints=transformCubPoints(xi,zC(:,curMeas),SR(:,:,curMeas));

    %Convert all of the points into refraction-correupted RUV space
    cubPointsRUV=Cart2RuvStdRefrac(cubPoints,useHalfRange,zTx,zRx,M,Ns,false,ce,ellipsOpts);
    
    %Extract the first two moments of the transformed points.
    [zRuv(:,curMeas),RRuv(:,:,curMeas)]=calcMixtureMoments(cubPointsRUV,w);
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
