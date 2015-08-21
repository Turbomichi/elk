
! Copyright (C) 2012 J. K. Dewhurst, S. Sharma and E. K. U. Gross.
! This file is distributed under the terms of the GNU General Public License.
! See the file COPYING for license details.

subroutine vnlcore(wfmt,vmat)
use modmain
implicit none
! arguments
complex(8), intent(in) :: wfmt(lmmaxvr,nrcmtmax,natmtot,nspinor,nstsv)
complex(8), intent(inout) :: vmat(nstsv,nstsv)
! local variables
integer is,ia,ias,nrc
integer ist1,ist2,ist3,m
complex(8) z1
! allocatable arrays
complex(8), allocatable :: zrhomt(:,:,:)
complex(8), allocatable :: wfcr(:,:,:),zfmt(:,:)
! external functions
complex(8) zfmtinp
external zfmtinp
allocate(zrhomt(lmmaxvr,nrcmtmax,nstsv))
allocate(wfcr(lmmaxvr,nrcmtmax,2))
vmat(:,:)=0.d0
do is=1,nspecies
  nrc=nrcmt(is)
  do ia=1,natoms(is)
    ias=idxas(ia,is)
    do ist3=1,spnst(is)
      if (spcore(ist3,is)) then
        do m=-spk(ist3,is),spk(ist3,is)-1
! pass m-1/2 to wavefcr
          call wavefcr(.false.,lradstp,is,ia,ist3,m,nrcmtmax,wfcr)
!$OMP PARALLEL DEFAULT(SHARED) PRIVATE(zfmt)
!$OMP DO
          do ist1=1,nstsv
            allocate(zfmt(lmmaxvr,nrcmtmax))
! calculate the complex overlap density in spherical harmonics
            zfmt(:,1:nrc)=conjg(wfcr(:,1:nrc,1))*wfmt(:,1:nrc,ias,1,ist1)
            if (spinpol) then
              zfmt(:,1:nrc)=zfmt(:,1:nrc) &
               +conjg(wfcr(:,1:nrc,2))*wfmt(:,1:nrc,ias,2,ist1)
            end if
            call zgemm('N','N',lmmaxvr,nrc,lmmaxvr,zone,zfshtvr,lmmaxvr,zfmt, &
             lmmaxvr,zzero,zrhomt(:,:,ist1),lmmaxvr)
            deallocate(zfmt)
          end do
!$OMP END DO
!$OMP END PARALLEL
!$OMP PARALLEL DEFAULT(SHARED) PRIVATE(zfmt,ist1,z1)
!$OMP DO
          do ist2=1,nstsv
            allocate(zfmt(lmmaxvr,nrcmtmax))
            call zpotclmt(lmaxvr,nrc,rcmt(:,is),lmmaxvr,zrhomt(:,:,ist2),zfmt)
            do ist1=1,ist2
              z1=zfmtinp(.true.,lmmaxvr,nrc,rcmt(:,is),lmmaxvr, &
               zrhomt(:,:,ist1),zfmt)
!$OMP CRITICAL
              vmat(ist1,ist2)=vmat(ist1,ist2)-z1
!$OMP END CRITICAL
            end do
            deallocate(zfmt)
          end do
!$OMP END DO
!$OMP END PARALLEL
        end do
      end if
    end do
  end do
end do
! set the lower triangular part of the matrix
do ist1=1,nstsv
  do ist2=1,ist1-1
    vmat(ist1,ist2)=conjg(vmat(ist2,ist1))
  end do
end do
! scale the non-local matrix elements in the case of a hybrid functional
if (hybrid) vmat(:,:)=hybridc*vmat(:,:)
deallocate(zrhomt,wfcr)
return
end subroutine
