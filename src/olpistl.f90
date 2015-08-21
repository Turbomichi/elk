
! Copyright (C) 2002-2005 J. K. Dewhurst, S. Sharma and C. Ambrosch-Draxl.
! This file is distributed under the terms of the GNU General Public License.
! See the file COPYING for license details.

!BOP
! !ROUTINE: olpistl
! !INTERFACE:
subroutine olpistl(ngp,igpig,o)
! !USES:
use modmain
! !INPUT/OUTPUT PARAMETERS:
!   ngp   : number of G+p-vectors (in,integer)
!   igpig : index from G+p-vectors to G-vectors (in,integer(ngkmax))
!   o     : overlap matrix (inout,complex(*))
! !DESCRIPTION:
!   Computes the interstitial contribution to the overlap matrix for the APW
!   basis functions. The overlap is given by
!   $$ O^{\rm I}({\bf G+k,G'+k})=\tilde{\Theta}({\bf G-G'}), $$
!   where $\tilde{\Theta}$ is the characteristic function. See routine
!   {\tt gencfun}.
!
! !REVISION HISTORY:
!   Created April 2003 (JKD)
!EOP
!BOC
implicit none
! arguments
integer, intent(in) :: ngp
integer, intent(in) :: igpig(ngkmax)
complex(8), intent(inout) :: o(*)
! local variables
integer ld,iv(3),jv(3),i,j,k
ld=ngp+nlotot
!$OMP PARALLEL DEFAULT(SHARED) PRIVATE(k,jv,i,iv)
!$OMP DO
do j=1,ngp
  k=(j-1)*ld
  jv(:)=ivg(:,igpig(j))
  do i=1,j
    k=k+1
    iv(:)=ivg(:,igpig(i))-jv(:)
    o(k)=o(k)+cfunig(ivgig(iv(1),iv(2),iv(3)))
  end do
end do
!$OMP END DO
!$OMP END PARALLEL
return
end subroutine
!EOC

