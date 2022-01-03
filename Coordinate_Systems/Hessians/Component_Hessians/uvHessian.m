function HTotal=uvHessian(xG,lRx,M)
%%UVHESSIAN Determine the Hessian matrix (second derivative matrix) of a
%           direction cosine measurement with respect to 3D position.
%           Relativity and atmospheric effects are not taken into account.
%
%INPUTS: xG The 3XN target position vectors in the global coordinate system
%           with [x;y;z] components for which gradients are desired.
%       lRx The 3X1  position vector of the receiver. If omitted, the
%           receiver is placed at the origin.
%         M A 3X3 rotation matrix from the global coordinate system to the
%           orientation of the coordinate system at the receiver. If
%           omitted, it is assumed to be the identity matrix.
%
%OUTPUTS: HTotal A 3X3X2XN matrix such that for the ith measurement,
%          HTotal(:,:,1,i) is the Hessian matrix with respect to the u
%          component and HTotal(:,:,2,i) is the Hessian matrix with respect
%          to the v component. The elements in the matrices for each
%          component/ point are
%          ordered [d^2/(dxdx), d^2/(dxdy), d^2/(dxdz);
%                   d^2/(dydx), d^2/(dydy), d^2/(dydz);
%                   d^2/(dzdx), d^2/(dzdy), d^2/(dzdz)];
%          note that each matrix is symmetric (i.e.
%           d^2/(dydx)=d^2/(dxdy) ).
%
%A derivation of the components of the Jacobian is given in [1]. The
%Hessian is just one derivative higher.
%
%EXAMPLE:
%Here, we verify that a numerically differentiated Hessian is consistent
%with the analytic one produced by this function.
% xG=[100;-1000;500];
% lRx=[500;20;-400];
% epsVal=1e-5;
% M=randRotMat(3);
% 
% H=uvHessian(xG,lRx,M);
% 
% J=uvGradient(xG,lRx,M);
% JdX=uvGradient(xG+[epsVal;0;0],lRx,M);
% JdY=uvGradient(xG+[0;epsVal;0],lRx,M);
% JdZ=uvGradient(xG+[0;0;epsVal],lRx,M);
% HNumDiff=zeros(3,3,2);
% HNumDiff(1,1,1)=(JdX(1,1)-J(1,1))/epsVal;
% HNumDiff(1,2,1)=(JdX(1,2)-J(1,2))/epsVal;
% HNumDiff(2,1,1)=HNumDiff(1,2,1);
% HNumDiff(1,3,1)=(JdX(1,3)-J(1,3))/epsVal;
% HNumDiff(3,1,1)=HNumDiff(1,3,1);
% HNumDiff(2,2,1)=(JdY(1,2)-J(1,2))/epsVal;
% HNumDiff(2,3,1)=(JdY(1,3)-J(1,3))/epsVal;
% HNumDiff(3,2,1)=HNumDiff(2,3,1);
% HNumDiff(3,3,1)=(JdZ(1,3)-J(1,3))/epsVal;
% 
% HNumDiff(1,1,2)=(JdX(2,1)-J(2,1))/epsVal;
% HNumDiff(1,2,2)=(JdX(2,2)-J(2,2))/epsVal;
% HNumDiff(2,1,2)=HNumDiff(1,2,2);
% HNumDiff(1,3,2)=(JdX(2,3)-J(2,3))/epsVal;
% HNumDiff(3,1,2)=HNumDiff(1,3,2);
% HNumDiff(2,2,2)=(JdY(2,2)-J(2,2))/epsVal;
% HNumDiff(2,3,2)=(JdY(2,3)-J(2,3))/epsVal;
% HNumDiff(3,2,2)=HNumDiff(2,3,2);
% HNumDiff(3,3,2)=(JdZ(2,3)-J(2,3))/epsVal;
% 
% max(abs((H(:)-HNumDiff(:))./H(:)))
%The relative error will be on the order of 1e-6 or better, indicating good
%agreement between the numerical Hessian matrix and the actual Hessian
%matrix.
%
%REFERENCES:
%[1] D. F. Crouse, "Basic tracking using nonlinear 3D monostatic and
%    bistatic measurements," IEEE Aerospace and Electronic Systems
%    Magazine, vol. 29, no. 8, Part II, pp. 4-53, Aug. 2014.
%
%June 2017 David F.Crouse, Naval Research Laboratory, Washington D.C.
%(UNCLASSIFIED) DISTRIBUTION STATEMENT A. Approved for public release.

if(nargin<3||isempty(M))
   M=eye(3,3); 
end

if(nargin<2||isempty(lRx))
   lRx=zeros(3,1); 
end

N=size(xG,2);
HTotal=zeros(3,3,2,N);
for curPoint=1:N
    %Convert the state into the local coordinate system.
    xLocal=M*(xG(1:3)-lRx(1:3));
    
    x=xLocal(1);
    y=xLocal(2);
    z=xLocal(3);
    
    r5=norm(xLocal)^5;

    H=zeros(3,3,2);

    %u Hessian values
    %du/(dxdx)
    H(1,1,1)=-((3*x*(y^2+z^2))/r5);
    %du/(dydy)
    H(2,2,1)=-((x*(x^2-2*y^2+z^2))/r5);
    %du/(dzdz)
    H(3,3,1)=-((x*(x^2+y^2-2*z^2))/r5);
    %du/(dxdy)
    H(1,2,1)=-((y*(-2*x^2+y^2+z^2))/r5);
    %du/(dydx)
    H(2,1,1)=H(1,2,1);
    %du/(dxdz)
    H(1,3,1)=-((z*(-2*x^2+y^2+z^2))/r5);
    %du/(dzdx)
    H(3,1,1)=H(1,3,1);
    %du/(dydz)
    H(2,3,1)=(3*x*y*z)/r5;
    %du/(dzdy)
    H(3,2,1)=H(2,3,1);

    %v Hessian values
    %dv/(dxdx)
    H(1,1,2)=-((y*(-2*x^2+y^2+z^2))/r5);
    %dv/(dydy)
    H(2,2,2)=-((3*y*(x^2+z^2))/r5);
    %dv/(dzdz)
    H(3,3,2)=-((y*(x^2+y^2-2*z^2))/r5);
    %dv/(dxdy)
    H(1,2,2)=-((x*(x^2-2*y^2+z^2))/r5);
    %dv/(dydx)
    H(2,1,2)=H(1,2,2);
    %dv/(dxdz)
    H(1,3,2)=(3*x*y*z)/r5;
    %dv/(dzdx)
    H(3,1,2)=H(1,3,2);
    %dv/(dydz)
    H(2,3,2)=-((z*(x^2-2*y^2+z^2))/r5);
    %dv/(dzdy)
    H(3,2,2)=H(2,3,2);
    
    %Rotate the values back into global coordinates
    HTotal(:,:,1,curPoint)=M'*H(:,:,1)*M;
    HTotal(:,:,2,curPoint)=M'*H(:,:,2)*M;
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
