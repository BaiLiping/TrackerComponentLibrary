function [grid,transMat]=createGridFromCovMat(mat,numPts,center,gamma)
%%CREATEGRIDFROMCOVMAT Generates a grid of points mapped from the unit
%                      square by the given matrix and center.
%
%INPUTS:
% mat: A numDim-by-numDim matrix.
% numPts: A scalar or numDim length vector. If a vector, each dimension has
%         the corresponding number of points on its axis. If a scalar, all
%         dimensions are given the same number of points.
% center: A numDim length vector indicating the point on which the
%         ellipse is centered. If center is given and nonempty, all points
%         in the grid are translated appropriately. Otherwise, the center
%         is the origin.
% gamma: A scaling factor for the eigenvalues of mat. Note that each
%        eigenvalue is multiplied by the square root of gamma. For the
%        inverse of a covariance matrix, this factor can be chosen as
%        ChiSquareD.invCDF(prob,numDim), where prob is the probability of
%        the true value falling within the ellipse. If not given, gamma
%        defaults to the value of the inverse CDF of a Chi-square
%        distribution which corresponds to a probability of 0.9997,
%        about 3-sigma. If a simple mapping from the unit square is desired
%        with no additional scaling, this value should be set to 1.
%
%OUTPUTS:
% grid: A numDim-by-prod(numPts) matrix containing states.
% transMat: A numDim-by-numDim matrix used to transform points by rotating
%           and scaling in the same manner as used to generate the points
%           in grid prior to translation by center.
%
%EXAMPLE-1: A comparison between ellipses generated by matrices using
%           drawEllipse and the corresponding grid points generated
%           by this function.
% z=[[4;3],[-25;-25]];
% A=zeros(2,2,2);
% A(:,:,1)=[4,-2;
% -2,5];
% A(:,:,2)=[15,10;
% 10,15];
% %Plot true ellipses
% figure(); hold on;
% drawEllipse(z(:,1),inv(A(:,:,1)),[],'LineWidth',2)
% drawEllipse(z(:,2),inv(A(:,:,2)),[],'LineWidth',2)
% %Plot grid
% grid1 = createGridFromCovMat(A(:,:,1),[10,20],z(:,1));
% grid2 = createGridFromCovMat(A(:,:,2),[10,20],z(:,2));
% plot(grid1(1,:),grid1(2,:),'ok')
% plot(grid2(1,:),grid2(2,:),'^k')
%
%EXAMPLE-2: A demonstration of the gridding in 3D. The grid points are
%           shown as a line to demonstrate the grid ordering and a blue dot
%           is drawn on the first point in the grid.
% figure();hold on;
% z = [25;15;100];
% A = [3,2,1;
% 2,5,2;
% 1,2,1];
% grid = createGridFromCovMat(A,5,z);
% plot3(grid(1,:),grid(2,:),grid(3,:),'k^-','LineWidth',2,'MarkerSize',1)
% drawEllipse(z,inv(A),[],'FaceAlpha',0.25)
% plot3(grid(1,1),grid(2,1),grid(3,1),'bo','MarkerFaceColor','b')
% view(25,7)
% grid on
%
%August 2021 Codie T. Lewis, Naval Research Laboratory, Washington D.C.
%(UNCLASSIFIED) DISTRIBUTION STATEMENT A. Approved for public release.

% Check mat
if isempty(mat)
    grid = [];
    return
elseif size(mat,1)~=size(mat,2)||length(size(mat))>2
    error('Parameter mat must be a square matrix.')
end
numDim = size(mat,1);

% Check numPts
if isempty(numPts)||prod(numPts)==0
    grid = [];
    return
elseif sum(numPts<0)>0
    error('All entries in numPts must be nonnegative.')
elseif isscalar(numPts)
    numPts = numPts*ones(1,numDim);
elseif length(numPts)~=numDim
    error('Parameter numPts must be a scalar or a vector of length equal to mat.')
end

% Check center
if ~exist('center','var')||isempty(center)
    center = zeros(numDim,1);
end

% Check gamma
if ~exist('gamma','var')||isempty(gamma)
    gamma = ChiSquareD.invCDF(0.9997,numDim);
end

[U,S] = schur(mat);
for idx = 1:numDim
    S(idx,idx) = sqrt(gamma*S(idx,idx));
end
transMat = U*S;

gridAxes = cell(1,numDim);
for dim = 1:numDim
    gridAxes{dim} = linspace(-1,1,numPts(dim));
end
ndMats = cell(1,numDim);
[ndMats{:}] = ndgrid(gridAxes{:});
ndGrid = zeros(numDim,numel(ndMats{1}));
for dim = 1:numDim
    ndGrid(dim,:) = ndMats{dim}(:)';
end
grid = zeros(numDim,size(ndGrid,2));
for idx = 1:size(ndGrid,2)
    grid(:,idx) = transMat*ndGrid(:,idx)+center;
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
