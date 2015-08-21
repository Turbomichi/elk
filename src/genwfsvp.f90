
! Copyright (C) 2011 S. Sharma, J. K. Dewhurst and E. K. U. Gross.
! This file is distributed under the terms of the GNU General Public License.
! See the file COPYING for license details.

subroutine genwfsvp(tsh,tgp,vpl,wfmt,ld,wfir)
use modmain
implicit none
! arguments
logical, intent(in) :: tsh
logical, intent(in) :: tgp
real(8), intent(in) :: vpl(3)
complex(8), intent(out) :: wfmt(lmmaxvr,nrcmtmax,natmtot,nspinor,nstsv)
integer, intent(in) :: ld
complex(8), intent(out) :: wfir(ld,nspinor,nstsv)
! local variables
integer ispn,igp
real(8) vl(3),vc(3)
! automatic arrays
integer ngp(nspnfv)
! allocatable arrays
integer, allocatable :: igpig(:,:)
real(8), allocatable :: vgpl(:,:,:),vgpc(:,:),gpc(:),tpgpc(:,:)
complex(8), allocatable :: sfacgp(:,:),apwalm(:,:,:,:,:)
complex(8), allocatable :: evecfv(:,:,:),evecsv(:,:)
allocate(igpig(ngkmax,nspnfv))
allocate(vgpl(3,ngkmax,nspnfv),vgpc(3,ngkmax))
allocate(gpc(ngkmax),tpgpc(2,ngkmax))
allocate(sfacgp(ngkmax,natmtot))
allocate(apwalm(ngkmax,apwordmax,lmmaxapw,natmtot,nspnfv))
! loop over first-variational spins
do ispn=1,nspnfv
  vl(:)=vpl(:)
  vc(:)=bvec(:,1)*vpl(1)+bvec(:,2)*vpl(2)+bvec(:,3)*vpl(3)
! spin-spiral case
  if (spinsprl) then
    if (ispn.eq.1) then
      vl(:)=vl(:)+0.5d0*vqlss(:)
      vc(:)=vc(:)+0.5d0*vqcss(:)
    else
      vl(:)=vl(:)-0.5d0*vqlss(:)
      vc(:)=vc(:)-0.5d0*vqcss(:)
    end if
  end if
! generate the G+p-vectors
  call gengpvec(vl,vc,ngp(ispn),igpig(:,ispn),vgpl(:,:,ispn),vgpc)
! generate the spherical coordinates of the G+p-vectors
  do igp=1,ngp(ispn)
    call sphcrd(vgpc(:,igp),gpc(igp),tpgpc(:,igp))
  end do
! generate structure factors for G+p-vectors
  call gensfacgp(ngp(ispn),vgpc,ngkmax,sfacgp)
! find the matching coefficients
  call match(ngp(ispn),gpc,tpgpc,sfacgp,apwalm(:,:,:,:,ispn))
end do
deallocate(vgpc,gpc,sfacgp)
! get the first- and second-variational eigenvectors from file
allocate(evecfv(nmatmax,nstfv,nspnfv))
allocate(evecsv(nstsv,nstsv))
call getevecfv(vpl,vgpl,evecfv)
call getevecsv(vpl,evecsv)
deallocate(vgpl)
! calculate the second-variational wavefunctions for all states
call genwfsv(tsh,tgp,.false.,ngp,igpig,evalsv,apwalm,evecfv,evecsv,wfmt,ld,wfir)
deallocate(igpig,apwalm,evecfv,evecsv)
return
end subroutine
