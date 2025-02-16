!> \file GFS_MP_generic.F90
!! This file contains the subroutines that calculate diagnotics variables
!! before/after calling any microphysics scheme:

!> This module contains the CCPP-compliant MP generic pre interstitial codes.
      module GFS_MP_generic_pre
      contains

      subroutine GFS_MP_generic_pre_init()
      end subroutine GFS_MP_generic_pre_init

!> \section arg_table_GFS_MP_generic_pre_run Argument Table
!! \htmlinclude GFS_MP_generic_pre_run.html
!!
      subroutine GFS_MP_generic_pre_run(im, levs, ldiag3d, qdiag3d, do_aw, ntcw, nncl, &
                                        ntrac, gt0, gq0, save_t, save_q, num_dfi_radar, errmsg, errflg)
!
      use machine,               only: kind_phys

      implicit none
      integer,                                intent(in) :: im, levs, ntcw, nncl, ntrac, num_dfi_radar
      logical,                                intent(in) :: ldiag3d, qdiag3d, do_aw
      real(kind=kind_phys), dimension(:,:),   intent(in) :: gt0
      real(kind=kind_phys), dimension(:,:,:), intent(in) :: gq0

      real(kind=kind_phys), dimension(:,:),   intent(inout) :: save_t
      real(kind=kind_phys), dimension(:,:,:), intent(inout) :: save_q

      character(len=*), intent(out) :: errmsg
      integer, intent(out) :: errflg

      integer :: i, k, n

      ! Initialize CCPP error handling variables
      errmsg = ''
      errflg = 0

      if (ldiag3d .or. do_aw .or. num_dfi_radar>0) then
        do k=1,levs
          do i=1,im
            save_t(i,k) = gt0(i,k)
          enddo
        enddo
      endif
      if (ldiag3d .or. do_aw) then
        if(qdiag3d) then
           do n=1,ntrac
              do k=1,levs
                 do i=1,im
                    save_q(i,k,n) = gq0(i,k,n)
                 enddo
              enddo
           enddo
        else if(do_aw) then
           ! if qdiag3d, all q are saved already
           save_q(1:im,:,1) = gq0(1:im,:,1)
           do n=ntcw,ntcw+nncl-1
              save_q(1:im,:,n) = gq0(1:im,:,n)
           enddo
        endif
      endif

      end subroutine GFS_MP_generic_pre_run

      subroutine GFS_MP_generic_pre_finalize()
      end subroutine GFS_MP_generic_pre_finalize

      end module GFS_MP_generic_pre

!> This module contains the subroutine that calculates 
!! precipitation type and its post, which provides precipitation forcing
!! to LSM.
      module GFS_MP_generic_post
      contains

      subroutine GFS_MP_generic_post_init()
      end subroutine GFS_MP_generic_post_init

!>\defgroup gfs_calpreciptype GFS Precipitation Type Diagnostics Module
!! \brief If dominant precip type is requested (i.e., Zhao-Carr MP scheme), 4 more algorithms in calpreciptype()
!! will be called.  the tallies are then summed in calwxt_dominant(). For GFDL cloud MP scheme, determine convective 
!! rain/snow by surface temperature;  and determine explicit rain/snow by rain/snow coming out directly from MP.
!! 
!! \section arg_table_GFS_MP_generic_post_run Argument Table
!! \htmlinclude GFS_MP_generic_post_run.html
!!
!> \section gfs_mp_gen GFS MP Generic Post General Algorithm
!> @{
      subroutine GFS_MP_generic_post_run(                                                                                 &
        im, levs, kdt, nrcm, nncl, ntcw, ntrac, imp_physics, imp_physics_gfdl, imp_physics_thompson,                      &
        imp_physics_mg, imp_physics_fer_hires, cal_pre, cplflx, cplchm, con_g, rainmin, dtf, frain, rainc,                &
        rain1, rann, xlat, xlon, gt0, gq0, prsl, prsi, phii, tsfc, ice, snow, graupel, save_t, save_q, rain0, ice0, snow0,&
        graupel0, del, rain, domr_diag, domzr_diag, domip_diag, doms_diag, tprcp, srflag, sr, cnvprcp, totprcp, totice,   &
        totsnw, totgrp, cnvprcpb, totprcpb, toticeb, totsnwb, totgrpb, rain_cpl, rainc_cpl, snow_cpl, pwat,               &
        drain_cpl, dsnow_cpl, lsm, lsm_ruc, lsm_noahmp, raincprv, rainncprv, iceprv, snowprv,                             &
        graupelprv, draincprv, drainncprv, diceprv, dsnowprv, dgraupelprv, dtp, dfi_radar_max_intervals,                  &
        dtend, dtidx, index_of_temperature, index_of_process_mp,ldiag3d, qdiag3d, lssav, num_dfi_radar, fh_dfi_radar,     &
        index_of_process_dfi_radar, ix_dfi_radar, dfi_radar_tten, radar_tten_limits, fhour, errmsg, errflg)
!
      use machine, only: kind_phys

      implicit none

      integer, intent(in) :: im, levs, kdt, nrcm, nncl, ntcw, ntrac, num_dfi_radar, index_of_process_dfi_radar
      integer, intent(in) :: imp_physics, imp_physics_gfdl, imp_physics_thompson, imp_physics_mg, imp_physics_fer_hires
      logical, intent(in) :: cal_pre, lssav, ldiag3d, qdiag3d, cplflx, cplchm
      integer, intent(in) :: index_of_temperature,index_of_process_mp

      integer                                                :: dfi_radar_max_intervals
      real(kind=kind_phys),                    intent(in)    :: fh_dfi_radar(:), fhour
      real(kind=kind_phys),                    intent(in)    :: radar_tten_limits(:)
      integer                                                :: ix_dfi_radar(:)
      real(kind=kind_phys), dimension(:,:),    intent(inout) :: gt0

      real(kind=kind_phys),                    intent(in)    :: dtf, frain, con_g, rainmin
      real(kind=kind_phys), dimension(:),      intent(in)    :: rain1, xlat, xlon, tsfc
      real(kind=kind_phys), dimension(:),      intent(inout) :: ice, snow, graupel, rainc
      real(kind=kind_phys), dimension(:),      intent(in)    :: rain0, ice0, snow0, graupel0
      real(kind=kind_phys), dimension(:,:),    intent(in)    :: rann
      real(kind=kind_phys), dimension(:,:),    intent(in)    :: prsl, save_t, del
      real(kind=kind_phys), dimension(:,:),    intent(in)    :: prsi, phii
      real(kind=kind_phys), dimension(:,:,:),  intent(in)    :: gq0, save_q

      real(kind=kind_phys), dimension(:,:,:),  intent(in)    :: dfi_radar_tten

      real(kind=kind_phys), dimension(:),      intent(in   ) :: sr
      real(kind=kind_phys), dimension(:),      intent(inout) :: rain, domr_diag, domzr_diag, domip_diag, doms_diag, tprcp,  &
                                                                srflag, cnvprcp, totprcp, totice, totsnw, totgrp, cnvprcpb, &
                                                                totprcpb, toticeb, totsnwb, totgrpb, pwat
      real(kind=kind_phys), dimension(:),      intent(inout) :: rain_cpl, rainc_cpl, snow_cpl

      real(kind=kind_phys), dimension(:,:,:),   intent(inout) :: dtend
      integer,         dimension(:,:), intent(in)    :: dtidx

      ! Stochastic physics / surface perturbations
      real(kind=kind_phys), dimension(:),      intent(inout) :: drain_cpl, dsnow_cpl

      ! Rainfall variables previous time step
      integer, intent(in) :: lsm, lsm_ruc, lsm_noahmp
      real(kind=kind_phys), dimension(:),      intent(inout) :: raincprv
      real(kind=kind_phys), dimension(:),      intent(inout) :: rainncprv
      real(kind=kind_phys), dimension(:),      intent(inout) :: iceprv
      real(kind=kind_phys), dimension(:),      intent(inout) :: snowprv
      real(kind=kind_phys), dimension(:),      intent(inout) :: graupelprv
      real(kind=kind_phys), dimension(:),      intent(inout) :: draincprv
      real(kind=kind_phys), dimension(:),      intent(inout) :: drainncprv
      real(kind=kind_phys), dimension(:),      intent(inout) :: diceprv
      real(kind=kind_phys), dimension(:),      intent(inout) :: dsnowprv
      real(kind=kind_phys), dimension(:),      intent(inout) :: dgraupelprv

      real(kind=kind_phys),                    intent(in)    :: dtp

      ! CCPP error handling
      character(len=*), intent(out) :: errmsg
      integer, intent(out) :: errflg

      ! DH* TODO: CLEANUP, all of these should be coming in through the argument list
      real(kind=kind_phys), parameter :: con_p001= 0.001_kind_phys
      real(kind=kind_phys), parameter :: con_day = 86400.0_kind_phys
      real(kind=kind_phys), parameter :: p850    = 85000.0_kind_phys
      ! *DH

      integer :: i, k, ic, itrac, idtend, itime, idtend_radar, idtend_mp

      real(kind=kind_phys), parameter :: zero = 0.0_kind_phys, one = 1.0_kind_phys
      real(kind=kind_phys) :: crain, csnow, onebg, tem, total_precip, tem1, tem2, ttend
      real(kind=kind_phys), dimension(im) :: domr, domzr, domip, doms, t850, work1

      ! Initialize CCPP error handling variables
      errmsg = ''
      errflg = 0

      onebg = one/con_g
      
      do i = 1, im
        rain(i) = rainc(i) + frain * rain1(i) ! time-step convective plus explicit
      enddo

!> - If requested (e.g. Zhao-Carr MP scheme), call calpreciptype() to calculate dominant 
!! precipitation type.
      ! DH* TODO - Fix wrong code in non-CCPP build (GFS_physics_driver)
      ! and use commented lines here (keep wrong version for bit-for-bit):
      ! put ice, snow, graupel on dynamics timestep. The way the code in
      ! GFS_physics_driver is written, Diag%{graupel,ice,snow} are on the
      ! physics timestep, while Diag%{rain,rainc} and all totprecip etc
      ! are on the dynamics timestep. Confusing, but works if frain=1. *DH
      if (imp_physics == imp_physics_gfdl) then
        tprcp   = max(zero, rain)               ! clu: rain -> tprcp
        !graupel = frain*graupel0
        !ice     = frain*ice0
        !snow    = frain*snow0
        graupel = graupel0
        ice     = ice0
        snow    = snow0
      ! Do it right from the beginning for Thompson
      else if (imp_physics == imp_physics_thompson) then
        tprcp   = max (zero, rainc + frain * rain1) ! time-step convective and explicit precip
        graupel = frain*graupel0              ! time-step graupel
        ice     = frain*ice0                  ! time-step ice
        snow    = frain*snow0                 ! time-step snow

      else if (imp_physics == imp_physics_fer_hires) then
        tprcp   = max (zero, rain) ! time-step convective and explicit precip
        ice     = frain*rain1*sr                  ! time-step ice
      end if
      
      if (lsm==lsm_ruc .or. lsm==lsm_noahmp) then
        raincprv(:)   = rainc(:)
        rainncprv(:)  = frain * rain1(:)
        iceprv(:)     = ice(:)
        snowprv(:)    = snow(:)
        graupelprv(:) = graupel(:)
        !for NoahMP, calculate precipitation rates from liquid water equivalent thickness for use in next time step
        !Note (GJF): Precipitation LWE thicknesses are multiplied by the frain factor, and are thus on the dynamics time step, but the conversion as written
        !            (with dtp in the denominator) assumes the rate is calculated on the physics time step. This only works as expected when dtf=dtp (i.e. when frain=1).
        if (lsm == lsm_noahmp) then
          tem = one / (dtp*con_p001) !GJF: This conversion was taken from GFS_physics_driver.F90, but should denominator also have the frain factor?
          draincprv(:)   = tem * raincprv(:)
          drainncprv(:)  = tem * rainncprv(:)
          dsnowprv(:)    = tem * snowprv(:)
          dgraupelprv(:) = tem * graupelprv(:)
          diceprv(:)     = tem * iceprv(:)
        end if
      end if

      if (cal_pre) then       ! hchuang: add dominant precipitation type algorithm
!
        call calpreciptype (kdt, nrcm, im, im, levs, levs+1, &
                            rann, xlat, xlon, gt0,           &
                            gq0(:,:,1), prsl, prsi,          &
                            rain, phii, tsfc,                &  ! input
                            domr, domzr, domip, doms)           ! output
!
!       HCHUANG: use new precipitation type to decide snow flag for LSM snow accumulation

        if (imp_physics /= imp_physics_gfdl .and. imp_physics /= imp_physics_thompson) then
          do i=1,im
            tprcp(i)  = max(zero, rain(i) )
            if(doms(i) > zero .or. domip(i) > zero) then
              srflag(i) = one
            else
              srflag(i) = zero
            end if
          enddo
        endif
        if (lssav) then
          do i=1,im
              domr_diag(i)  = domr_diag(i)  + domr(i)  * dtf
              domzr_diag(i) = domzr_diag(i) + domzr(i) * dtf
              domip_diag(i) = domip_diag(i) + domip(i) * dtf
              doms_diag(i)  = doms_diag(i)  + doms(i)  * dtf
          enddo
        endif

      endif

      do itime=1,num_dfi_radar
         if(ix_dfi_radar(itime)<1) cycle
         if(fhour<fh_dfi_radar(itime)) cycle
         if(fhour>=fh_dfi_radar(itime+1)) cycle
         exit
      enddo
      if_radar: if(itime<=num_dfi_radar) then
         radar_k: do k=3,levs-2 ! Avoid model top and bottom in case DA forgets to
            radar_i: do i=1,im
              ttend = dfi_radar_tten(i,k,itime)
              if_active: if (ttend>-19) then
                 ttend = max(ttend,radar_tten_limits(1))
                 ttend = min(ttend,radar_tten_limits(2))

                 ! add radar temp tendency
                 ! there is radar coverage
                 gt0(i,k) = save_t(i,k) + ttend*dtp
              end if if_active
           end do radar_i
        end do radar_k
        if(ldiag3d) then
           idtend_radar = dtidx(index_of_temperature,index_of_process_dfi_radar)
           idtend_mp = dtidx(index_of_temperature,index_of_process_mp)
           if(idtend_radar>0 .or. idtend_mp>0) then
              if(idtend_mp>0) then
                 dtend(:,1:2,idtend_mp) = dtend(:,1:2,idtend_mp) + (gt0(:,1:2)-save_t(:,1:2))*frain
              endif
              do k=3,levs-2 ! Avoid model top and bottom in case DA forgets to
                 do i=1,im
                    ttend = dfi_radar_tten(i,k,itime)
                    if (ttend>-19) then
                       if(idtend_radar>0) then
                          dtend(i,k,idtend_radar) = dtend(i,k,idtend_radar) + (gt0(i,k)-save_t(i,k)) * frain
                       endif
                    else if(idtend_mp>0) then
                       dtend(i,k,idtend_mp) = dtend(i,k,idtend_mp) + (gt0(i,k)-save_t(i,k)) * frain
                    endif
                 enddo
              enddo
              if(idtend_mp>0) then
                 dtend(:,levs-1:levs,idtend_mp) = dtend(:,levs-1:levs,idtend_mp) + (gt0(:,levs-1:levs)-save_t(:,levs-1:levs))*frain
              endif
           endif
        endif
      endif if_radar

      t850(1:im) = gt0(1:im,1)

      do k = 1, levs-1
        do i = 1, im
          if (prsl(i,k) > p850 .and. prsl(i,k+1) <= p850) then
            t850(i) = gt0(i,k) - (prsl(i,k)-p850) /  &
                      (prsl(i,k)-prsl(i,k+1)) *      &
                      (gt0(i,k)-gt0(i,k+1))
          endif
        enddo
      enddo

      ! Conversion factor from mm per day to m per physics timestep 
      tem = dtp * con_p001 / con_day

!> - For GFDL and Thompson MP scheme, determine convective snow by surface temperature;
!! and determine explicit rain/snow by snow/ice/graupel coming out directly from MP
!! and convective rainfall from the cumulus scheme if the surface temperature is below
!! \f$0^oC\f$.

      if (imp_physics == imp_physics_gfdl .or. imp_physics == imp_physics_thompson) then

! determine convective rain/snow by surface temperature
! determine large-scale rain/snow by rain/snow coming out directly from MP
       
        if (lsm /= lsm_ruc) then
          do i = 1, im
            !tprcp(i)  = max(0.0, rain(i) )! clu: rain -> tprcp ! DH now lines 245-250
            srflag(i) = zero                     ! clu: default srflag as 'rain' (i.e. 0)
            if (tsfc(i) >= 273.15_kind_phys) then
              crain = rainc(i)
              csnow = zero
            else
              crain = zero
              csnow = rainc(i)
            endif
!            if (snow0(i,1)+ice0(i,1)+graupel0(i,1)+csnow > rain0(i,1)+crain) then
!            if (snow0(i)+ice0(i)+graupel0(i)+csnow > 0.0) then
!              Sfcprop%srflag(i) = 1.                   ! clu: set srflag to 'snow' (i.e. 1)
!            endif
            total_precip = snow0(i)+ice0(i)+graupel0(i)+rain0(i)+rainc(i)
            if (total_precip > rainmin) then
              srflag(i) = (snow0(i)+ice0(i)+graupel0(i)+csnow)/total_precip
            endif
          enddo
        else
          ! only for RUC LSM
          do i=1,im
            srflag(i) = sr(i)
          enddo
        endif ! lsm==lsm_ruc
      elseif( .not. cal_pre) then
        if (imp_physics == imp_physics_mg) then          ! MG microphysics
          do i=1,im
            if (rain(i) > rainmin) then
              tem1 = max(zero, (rain(i)-rainc(i))) * sr(i)
              tem2 = one / rain(i)
              if (t850(i) > 273.16_kind_phys) then
                srflag(i) = max(zero, min(one, tem1*tem2))
              else
                srflag(i) = max(zero, min(one, (tem1+rainc(i))*tem2))
              endif
            else
              srflag(i) = zero
              rain(i)   = zero
              rainc(i)  = zero
            endif
            tprcp(i)  = max(zero, rain(i))
          enddo
        else                                             ! not GFDL or MG or Thompson microphysics
          do i = 1, im
            tprcp(i)  = max(zero, rain(i))
            srflag(i) = sr(i)
          enddo
        endif
      endif

      if_save_fields: if (lssav) then
!        if (Model%me == 0) print *,'in phys drive, kdt=',Model%kdt, &
!          'totprcpb=', Diag%totprcpb(1),'totprcp=',Diag%totprcp(1), &
!          'rain=',Diag%rain(1)
        do i=1,im
          cnvprcp (i) = cnvprcp (i) + rainc(i)
          totprcp (i) = totprcp (i) + rain(i)
          totice  (i) = totice  (i) + ice(i)
          totsnw  (i) = totsnw  (i) + snow(i)
          totgrp  (i) = totgrp  (i) + graupel(i)

          cnvprcpb(i) = cnvprcpb(i) + rainc(i)
          totprcpb(i) = totprcpb(i) + rain(i)
          toticeb (i) = toticeb (i) + ice(i)
          totsnwb (i) = totsnwb (i) + snow(i)
          totgrpb (i) = totgrpb (i) + graupel(i)
        enddo

        if_tendency_diagnostics: if (ldiag3d) then
           idtend = dtidx(index_of_temperature,index_of_process_mp)
           if(idtend>=1) then
              do k=1,levs
                 do i=1,im
                    dtend(i,k,idtend) = dtend(i,k,idtend) + (gt0(i,k)-save_t(i,k)) * frain
                 enddo
              enddo
           endif
           if_tracer_diagnostics: if (qdiag3d) then
              dtend_q: do itrac=1,ntrac
                 idtend = dtidx(itrac+100,index_of_process_mp)
                 if(idtend>=1) then
                    do k=1,levs
                       do i=1,im
                          dtend(i,k,idtend) = dtend(i,k,idtend) + (gq0(i,k,itrac)-save_q(i,k,itrac)) * frain
                       enddo
                    enddo
                 endif
              enddo dtend_q
           endif if_tracer_diagnostics
        endif if_tendency_diagnostics
      endif if_save_fields

      if (cplflx .or. cplchm) then
        do i = 1, im
          dsnow_cpl(i)= max(zero, rain(i) * srflag(i))
          drain_cpl(i)= max(zero, rain(i) - dsnow_cpl(i))
          rain_cpl(i) = rain_cpl(i) + drain_cpl(i)
          snow_cpl(i) = snow_cpl(i) + dsnow_cpl(i)
        enddo
      endif

      if (cplchm) then
        do i = 1, im
          rainc_cpl(i) = rainc_cpl(i) + rainc(i)
        enddo
      endif

      pwat(:) = zero
      do k = 1, levs
        do i=1, im
          work1(i) = zero
        enddo
        if (nncl > 0) then
          do ic = ntcw, ntcw+nncl-1
            do i=1,im
              work1(i) = work1(i) + gq0(i,k,ic)
            enddo
          enddo
        endif
        do i=1,im
          pwat(i) = pwat(i) + del(i,k)*(gq0(i,k,1)+work1(i))
        enddo
      enddo
      do i=1,im
        pwat(i) = pwat(i) * onebg
      enddo


      end subroutine GFS_MP_generic_post_run
!> @}

      subroutine GFS_MP_generic_post_finalize()
      end subroutine GFS_MP_generic_post_finalize

      end module GFS_MP_generic_post
