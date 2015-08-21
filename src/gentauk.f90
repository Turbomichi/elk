
! Copyright (C) 2011 J. K. Dewhurst, S. Sharma and E. K. U. Gross.
! This file is distributed under the terms of the GNU General Public License.
! See the file COPYING for license details.

subroutine gentauk(ik,taumt,tauir)
use modmain
implicit none
! arguments
integer, intent(in) :: ik
real(8), intent(inout) :: taumt(lmmaxvr,nrmtmax,natmtot,nspinor)
real(8), intent(inout) :: tauir(ngtot,nspinor)
! local variables
integer ispn,jspn,ist,is,ias
integer nr,nri,nrc,nrci
integer ir,irc,igk,ifg,i
real(8) t0
! allocatable arrays
complex(8), allocatable :: apwalm(:,:,:,:,:)
complex(8), allocatable :: evecfv(:,:),evecsv(:,:)
complex(8), allocatable :: wfmt(:,:,:,:,:),wfir(:,:,:)
complex(8), allocatable :: gzfmt(:,:,:),zfmt(:,:),zfft(:)
allocate(apwalm(ngkmax,apwordmax,lmmaxapw,natmtot,nspnfv))
allocate(evecfv(nmatmax,nstfv),evecsv(nstsv,nstsv))
allocate(wfmt(lmmaxvr,nrcmtmax,natmtot,nspinor,nstsv))
allocate(wfir(ngkmax,nspinor,nstsv))
allocate(gzfmt(lmmaxvr,nrcmtmax,3),zfmt(lmmaxvr,nrcmtmax))
allocate(zfft(ngtot))
! find the matching coefficients
do ispn=1,nspnfv
  call match(ngk(ispn,ik),gkc(:,ispn,ik),tpgkc(:,:,ispn,ik), &
   sfacgk(:,:,ispn,ik),apwalm(:,:,:,:,ispn))
end do
! get the eigenvectors from file
call getevecfv(vkl(:,ik),vgkl(:,:,:,ik),evecfv)
call getevecsv(vkl(:,ik),evecsv)
! calculate the second-variational wavefunctions for all states
call genwfsv(.true.,.true.,.true.,ngk(:,ik),igkig(:,:,ik),occsv(:,ik), &
 apwalm,evecfv,evecsv,wfmt,ngkmax,wfir)
!-------------------------!
!     muffin-tin part     !
!-------------------------!
do ist=1,nstsv
  if (abs(occsv(ist,ik)).lt.epsocc) cycle
  t0=0.5d0*wkpt(ik)*occsv(ist,ik)
  do ispn=1,nspinor
    do ias=1,natmtot
      is=idxis(ias)
      nr=nrmt(is)
      nri=nrmtinr(is)
      nrc=nrcmt(is)
      nrci=nrcmtinr(is)
! compute the gradient of the wavefunction
      call gradzfmt(nrc,nrci,rcmt(:,is),wfmt(:,:,ias,ispn,ist),nrcmtmax,gzfmt)
      do i=1,3
! convert gradient to spherical coordinates
        call zbsht(nrc,nrci,gzfmt(:,:,i),zfmt)
! add to total taumt
!$OMP CRITICAL
        irc=0
! inner part of muffin-tin
        do ir=1,nri,lradstp
          irc=irc+1
          taumt(1:lmmaxinr,ir,ias,ispn)=taumt(1:lmmaxinr,ir,ias,ispn) &
           +t0*(dble(zfmt(1:lmmaxinr,irc))**2+aimag(zfmt(1:lmmaxinr,irc))**2)
        end do
! outer part of muffin-tin
        do ir=nri+lradstp,nr,lradstp
          irc=irc+1
          taumt(:,ir,ias,ispn)=taumt(:,ir,ias,ispn) &
           +t0*(dble(zfmt(:,irc))**2+aimag(zfmt(:,irc))**2)
        end do
!$OMP END CRITICAL
      end do
    end do
  end do
end do
!---------------------------!
!     interstitial part     !
!---------------------------!
do ist=1,nstsv
  if (abs(occsv(ist,ik)).lt.epsocc) cycle
  t0=0.5d0*wkpt(ik)*occsv(ist,ik)/omega
  do ispn=1,nspinor
    jspn=jspnfv(ispn)
    do i=1,3
      zfft(:)=0.d0
      do igk=1,ngk(jspn,ik)
        ifg=igfft(igkig(igk,jspn,ik))
        zfft(ifg)=vgkc(i,igk,jspn,ik) &
         *cmplx(-aimag(wfir(igk,ispn,ist)),dble(wfir(igk,ispn,ist)),8)
      end do
      call zfftifc(3,ngridg,1,zfft)
!$OMP CRITICAL
      do ir=1,ngtot
        tauir(ir,ispn)=tauir(ir,ispn)+t0*(dble(zfft(ir))**2+aimag(zfft(ir))**2)
      end do
!$OMP END CRITICAL
    end do
  end do
end do
deallocate(apwalm,evecfv,evecsv)
deallocate(wfmt,wfir,gzfmt,zfmt,zfft)
return
end subroutine

