!>  \file radiation_clouds.f
!!  This file contains routines to compute cloud related quantities
!!  for radiation computations.

!              module_radiation_clouds description             !!!!!
!  ==========================================================  !!!!!
!                                                                      !
!    the 'radiation_clouds.f' contains:                                !
!                                                                      !
!       'module_radiation_clouds' ---  compute cloud related quantities!
!                for radiation computations                            !
!                                                                      !
!    the following are the externally accessable subroutines:          !
!                                                                      !
!       'cld_init'           --- initialization routine                !
!          inputs:                                                     !
!           ( si, NLAY, imp_physics,  me )                             !
!          outputs:                                                    !
!           ( none )                                                   !
!                                                                      !
!       'radiation_clouds_prop'         --- radiation cloud properties !
!            obtained from various cloud schemes                       !
!          inputs:                                                     !
!           (plyr,plvl,tlyr,tvly,qlyr,qstl,rhly,                       !
!            ccnd, ncndl, cnvw, cnvc, tracer1,                         !
!            xlat,xlon,slmsk,dz,delp, IX, LM, NLAY, NLP1,              !
!            deltaq, sup, me, icloud, kdt,                             !
!            ntrac, ntcw, ntiw, ntrw, ntsw, ntgl, ntclamt,             !
!            imp_physics, imp_physics_nssl, imp_physics_fer_hires,     !
!            imp_physics_gfdl, imp_physics_thompson, imp_physics_wsm6, !
!            imp_physics_zhao_carr, imp_physics_zhao_carr_pdf,         !
!            imp_physics_mg, iovr_rand, iovr_maxrand, iovr_max,        !
!            iovr_dcorr, iovr_exp, iovr_exprand, idcor_con,            !
!            idcor_hogan, idcor_oreopoulos,                            !
!            imfdeepcnv, imfdeepcnv_gf, do_mynnedmf, lgfdlmprad,       !
!            uni_cld, lmfshal, lmfdeep2, cldcov, clouds1,              !
!            effrl, effri, effrr, effrs, effr_in,                      !
!            effrl_inout, effri_inout, effrs_inout,                    !
!            lwp_ex, iwp_ex, lwp_fc, iwp_fc,                           !
!            dzlay, latdeg, julian, yearlen, gridkm,                   !
!          outputs:                                                    !
!            cld_frac, cld_lwp, cld_reliq, cld_iwp, cld_reice,         !
!            cld_rwp, cld_rerain, cld_swp, cld_resnow,                 !
!            clds,mtop,mbot,de_lgth,alpha)                             !
!                                                                      !
!    internal/external accessable subroutines:                                !
!       'progcld_zhao_carr'      --- zhao/moorthi prognostic cloud scheme     !
!       'progcld_zhao_carr_pdf'  --- zhao/moorthi prognostic cloud + pdfcld   !
!       'progcld_gfdl_lin'       --- GFDL-Lin cloud microphysics              !
!       'progcld_fer_hires'      --- Ferrier-Aligo cloud microphysics         !
!       'progcld_thompson_wsm6'  --- Thompson/wsm6 cloud microphysics (EMC)   !
!       'progclduni'             --- MG2/3 cloud microphysics                 !
!                                    (with/without SHOC) (EMC)                !
!                                    also used by GFDL MP (EMC)               !
!       'progcld_thompson'       --- Thompson MP (added by G. Thompson)       !
!       'gethml'                 --- get diagnostic hi, mid, low clouds       !
!                                                                      !
!    cloud property array description:                                 !
!          cld_frac  (:,:)  -  layer total cloud fraction              ! 
!          cld_lwp   (:,:)  -  layer cloud liq water path              ! 
!          cld_reliq (:,:)  -  mean effective radius for liquid cloud  !
!          cld_iwp   (:,:)  -  layer cloud ice water path              !
!          cld_reice (:,:)  -  mean effective radius for ice cloud     !
!          cld_rwp   (:,:)  -  layer rain drop water path              !
!          cld_rerain(:,:)  -  mean effective radius for rain drop     !
!   **     cld_swp   (:,:)  -  layer snow flake water path             !
!          cld_resnow(:,:)  -  mean effective radius for snow flake    !
!   ** fu's scheme need to be normalized by snow density (g/m**3/1.0e6)!
!                                                                      !
!    external modules referenced:                                      !
!                                                                      !
!       'module physparam'           in 'physparam.f'                  !
!       'module physcons'            in 'physcons.f'                   !
!       'module module_microphysics' in 'module_bfmicrophysics.f'      !
!                                                                      !
!                                                                      !
! program history log:                                                 !
!      nov 1992,   y.h., k.a.c, a.k. - cloud parameterization          !
!        'cldjms' patterned after slingo and slingo's work (jgr,       !
!        1992), stratiform clouds are allowed in any layer except      !
!        the surface and upper stratosphere. the relative humidity     !
!        criterion may cery in different model layers.                 !
!      mar 1993,   kenneth campana   - created original crhtab tables  !
!        for critical rh look up references.
!      feb 1994,   kenneth campana   - modified to use only one table  !
!        for all forecast hours.                                       !
!      oct 1995,   kenneth campana   - tuned cloud rh curves           !
!        rh-cld relation from tables created using mitchell-hahn       !
!        tuning technique on airforce rtneph observations.             !
!      nov 1995,   kenneth campana   - the bl relationships used       !
!        below llyr, except in marine stratus regions.                 !
!      apr 1996,   kenneth campana   - save bl cld amt in cld(,5)      !
!      aug 1997,   kenneth campana   - smooth out last bunch of bins   !
!        of the rh look up tables                                      !
!      dec 1998,   s. moorthi        - added prognostic cloud method   !
!      apr 2003,   yu-tai hou        - rewritten in frotran 90         !
!        modulized form 'module_rad_clouds' from combining the original!
!        subroutines 'cldjms', 'cldprp', and 'gcljms'. and seperated   !
!        prognostic and diagnostic methods into two packages.          !
!      --- 2003,   s. moorthi        - adapted b. ferrier's prognostic !
!        cloud scheme to ncep gfs model as additional option.          !
!      apr 2004,   yu-tai hou        - separated calculation of the    !
!        averaged h,m,l,bl cloud amounts from each of the cld schemes  !
!        to become an shared individule subprogram 'gethml'.           !
!      apr 2005,   yu-tai hou        - modified cloud array and module !
!        structures.                                                   !
!      dec 2008,   yu-tai hou        - changed low-cld calculation,    !
!        now cantains clds from sfc layer and upward to the low/mid    !
!        boundary (include bl-cld). h,m,l clds domain boundaries are   !
!        adjusted for better agreement with observations.              !
!      jan 2011,   yu-tai hou        - changed virtual temperature     !
!        as input variable instead of originally computed inside the   !
!        two prognostic cld schemes 'progcld_zhao_carr'                !
!      aug 2012,   yu-tai hou        - modified subroutine cld_init    !
!        to pass all fixed control variables at the start. and set     !
!        their correponding internal module variables to be used by    !
!        module subroutines.                                           !
!      nov 2012,   yu-tai hou        - modified control parameters     !
!        thru module 'physparam'.                                      !
!      apr 2013,   h.lin/y.hou       - corrected error in calculating  !
!        llyr for different vertical indexing directions.              !
!      jul 2013, r. sun/h. pan       - modified to use pdf cloud and   !
!        convective cloud cover and water for radiation                !
!                                                                      !
!      jul 2014 s. moorthi - merging with gfs version                  !
!      feb 2017 a. cheng   - add odepth output, effective radius input !
!      Jan 2018 S Moorthi  - update to include physics from ipdv4      !
!      jun 2018 h-m lin/y-t hou   - removed the legacy subroutine      !
!        'diagcld1' for diagnostic cloud scheme, added new cloud       !
!        overlapping method of de-correlation length, and optimized    !
!        the code structure.                                           !
!      jul 2020, m.j. iacono - added rrtmg/mcica cloud overlap options !
!        exponential and exponential-random. each method can use       !
!        either a constant or a latitude-varying and day-of-year       !
!        varying decorrelation length selected with parameter "idcor". !
!                                                                      !
!      Jan 2022, Q.Liu  - add subroutine radiation_clouds_prop, and    !
!        move all the subroutine call "progcld*" from                  !
!        GFS_rrtmg_pre.F90 to this new subroutine                      !
!!!!!  ==========================================================  !!!!!
!!!!!                       end descriptions                       !!!!!
!!!!!  ==========================================================  !!!!!

!> \defgroup module_radiation_clouds RRTMG Clouds Module
!! @{
!! \brief This module computes cloud related quantities for radiation
!! computations.
!!
!! Knowledge of cloud properties and their vertical structure is
!! important for meteorological studies due to their impact on both the
!! Earth's radiation budget and adiabatic heating within the atmosphere.
!! Cloud properties in the US National Oceanic and Atmospheric
!! Administration National Centers for Environmental Prediction Global
!! Forecast System (GFS) include (i) cloud liquid/ice water path; (ii)
!! the fraction of clouds; (iii) effective radius of water/ice droplet:
!!
!! Cloud prediction model (namelist control parameter - \b NTCW, \b IMP_PHYSICS):
!!\n NTCW=0: legacy diagnostic cloud scheme based on RH-table lookup table
!!\n NTCW>0: prognostic cloud condensate
!!\n IMP_PHYSICS =98/99: Zhao-Carr-Sundqvist MP - Xu-Randall diagnostic cloud fraction
!!\n IMP_PHYSICS =11: GFDL MP - unified diagnostic cloud fraction provided by GFDL MP
!!
!! Cloud overlapping method (namelist control parameter - \b IOVR)
!!\n IOVR=0: randomly overlapping vertical cloud layers
!!\n IOVR=1: maximum-random overlapping vertical cloud layers
!!\n IOVR=2: maximum overlapping vertical cloud layers
!!\n IOVR=3: decorrelation length overlapping vertical cloud layers
!!\n IOVR=4: exponential overlapping vertical cloud layers
!!\n IOVR=5: exponential-random overlapping vertical cloud layers
!!
!! Sub-grid cloud approximation (namelist control parameter - \b ISUBC_LW=2, \b ISUBC_SW=2)
!!\n ISUBC=0: grid averaged quantities, without sub-grid cloud approximation
!!\n ISUBC=1: with McICA sub-grid approximation (use prescribed permutation seeds)
!!\n ISUBC=2: with McICA sub-grid approximation (use random permutation seeds)
!!
!!\version NCEP-Radiation_clouds    v5.1  Nov 2012
!!
!! @}

!> This module computes cloud related quantities for radiation computations.
      module module_radiation_clouds
!
      use physparam,           only : icldflg, iovr, idcor,             &
     &                                lcrick, lcnorm, lnoprec,          &
     &                                ivflip
      use physcons,            only : con_fvirt, con_ttp, con_rocp,     &
     &                                con_t0c, con_pi, con_g, con_rd,   &
     &                                con_thgni, decorr_con
      use module_microphysics, only : rsipath2
      use module_iounitdef,    only : NICLTUN
      use module_radiation_cloud_overlap, only: cmp_dcorr_lgth,         &
     &                                          get_alpha_exper
      use machine,             only : kind_phys
!
      implicit   none
!
      private

!  ---  version tag and last revision date
      character(40), parameter ::                                       &
     &   VTAGCLD='NCEP-Radiation_clouds    v5.1  Nov 2012 '
!    &   VTAGCLD='NCEP-Radiation_clouds    v5.0  Aug 2012 '

!  ---  set constant parameters
      real (kind=kind_phys), parameter :: gfac=1.0e5/con_g              &
     &,                                   gord=con_g/con_rd


      integer, parameter, public :: NF_CLDS = 9          !< number of fields in cloud array
      integer, parameter, public :: NK_CLDS = 3          !< number of cloud vertical domains

! pressure limits of cloud domain interfaces (low,mid,high) in mb (0.1kPa)
      real (kind=kind_phys), save :: ptopc(NK_CLDS+1,2)   !< pressure limits of cloud domain interfaces
                                                          !! (low, mid, high) in mb (0.1kPa)

!org  data ptopc / 1050., 642., 350., 0.0,  1050., 750., 500., 0.0 /
      data ptopc / 1050., 650., 400., 0.0,  1050., 750., 500., 0.0 /

!     real (kind=kind_phys), parameter :: climit = 0.01
      real (kind=kind_phys), parameter :: climit = 0.001, climit2=0.05
      real (kind=kind_phys), parameter :: ovcst  = 1.0 - 1.0e-8

      real (kind=kind_phys), parameter :: reliq_def = 10.0        !< default liq radius to 10 micron
      real (kind=kind_phys), parameter :: reice_def = 50.0        !< default ice radius to 50 micron
      real (kind=kind_phys), parameter :: rrain_def = 1000.0      !< default rain radius to 1000 micron
      real (kind=kind_phys), parameter :: rsnow_def = 250.0       !< default snow radius to 250 micron

      real (kind=kind_phys), parameter :: cldssa_def = 0.99       !< default cld single scat albedo
      real (kind=kind_phys), parameter :: cldasy_def = 0.84       !< default cld asymmetry factor

      integer  :: llyr   = 2                              !< upper limit of boundary layer clouds

      ! Default ice crystal sizes vs. temperature following Kristjansson and Mitchell
      real (kind=kind_phys), dimension(95), parameter :: retab =(/      &
     &                   5.92779, 6.26422, 6.61973, 6.99539, 7.39234,   &
     &           7.81177, 8.25496, 8.72323, 9.21800, 9.74075, 10.2930,  &
     &           10.8765, 11.4929, 12.1440, 12.8317, 13.5581, 14.2319,  &
     &           15.0351, 15.8799, 16.7674, 17.6986, 18.6744, 19.6955,  &
     &           20.7623, 21.8757, 23.0364, 24.2452, 25.5034, 26.8125,  &
     &           27.7895, 28.6450, 29.4167, 30.1088, 30.7306, 31.2943,  &
     &           31.8151, 32.3077, 32.7870, 33.2657, 33.7540, 34.2601,  &
     &           34.7892, 35.3442, 35.9255, 36.5316, 37.1602, 37.8078,  &
     &           38.4720, 39.1508, 39.8442, 40.5552, 41.2912, 42.0635,  &
     &           42.8876, 43.7863, 44.7853, 45.9170, 47.2165, 48.7221,  &
     &           50.4710, 52.4980, 54.8315, 57.4898, 60.4785, 63.7898,  &
     &           65.5604, 71.2885, 75.4113, 79.7368, 84.2351, 88.8833,  &
     &           93.6658, 98.5739, 103.603, 108.752, 114.025, 119.424,  &
     &           124.954, 130.630, 136.457, 142.446, 148.608, 154.956,  &
     &           161.503, 168.262, 175.248, 182.473, 189.952, 197.699,  &
     &           205.728, 214.055, 222.694, 231.661, 240.971, 250.639/)

      public progcld_zhao_carr, progcld_zhao_carr_pdf,                  &
     &       progcld_gfdl_lin, progclduni, progcld_fer_hires,           &
     &       cld_init, radiation_clouds_prop,                           &
     &       progcld_thompson_wsm6, progcld_thompson, cal_cldfra3,      &
     &       find_cloudLayers, adjust_cloudIce, adjust_cloudH2O,        &
     &       adjust_cloudFinal, gethml

! =================
      contains
! =================

!> \ingroup module_radiation_clouds
!> This subroutine is an initialization program for cloud-radiation
!! calculations and sets up boundary layer cloud top.
!!\param si              model vertical sigma layer interface
!!\param NLAY            vertical layer number
!!\param imp_physics     cloud microphysics scheme control flag
!!\n                     =99: Zhao-Carr/Sundqvist microphysics cloud
!!\n                     =98: Zhao-Carr/Sundqvist microphysics cloud = pdfcld
!!\n                     =11: GFDL microphysics cloud
!!\n                     =8:  Thompson microphysics
!!\n                     =6:  WSM6 microphysics
!!\n                     =10: MG microphysics
!!\n                     =15: Ferrier-Aligo microphysics
!!\n                     =17/18: NSSL microphysics
!!\param me              print control flag
!>\section cld_init General Algorithm
!! @{
      subroutine cld_init                                               &
     &     ( si, NLAY, imp_physics, me ) !  ---  inputs
!  ---  outputs:
!          ( none )

!  ===================================================================  !
!                                                                       !
! abstract: cld_init is an initialization program for cloud-radiation   !
!   calculations. it sets up boundary layer cloud top.                  !
!                                                                       !
!                                                                       !
! inputs:                                                               !
!   si (L+1)        : model vertical sigma layer interface              !
!   NLAY            : vertical layer number                             !
!   imp_physics     : MP identifier                                     !
!   me              : print control flag                                !
!                                                                       !
!  outputs: (none)                                                      !
!           to module variables                                         !
!                                                                       !
!  external module variables: (in physparam)                            !
!   icldflg         : cloud optical property scheme control flag        !
!                     =0: abort! diagnostic cloud method discontinued   !
!                     =1: model use prognostic cloud method             !
!   imp_physics         : cloud microphysics scheme control flag        !
!                     =99: zhao/carr/sundqvist microphysics cloud       !
!                     =98: zhao/carr/sundqvist microphysics cloud+pdfcld!
!                     =11: GFDL microphysics cloud                      !
!                     =8: Thompson microphysics                         !
!                     =6: WSM6 microphysics                             !
!                     =10: MG microphysics                              !
!   iovr            : control flag for cloud overlapping scheme         !
!                     =0: random overlapping clouds                     !
!                     =1: max/ran overlapping clouds                    !
!                     =2: maximum overlap clouds       (mcica only)     !
!                     =3: decorrelation-length overlap (mcica only)     !
!                     =4: exponential cloud overlap  (AER; mcica only)  !
!                     =5: exponential-random overlap (AER; mcica only)  !
!   ivflip          : control flag for direction of vertical index      !
!                     =0: index from toa to surface                     !
!                     =1: index from surface to toa                     !
!  usage:       call cld_init                                           !
!                                                                       !
!  subroutines called:    rhtable                                       !
!                                                                       !
!  ===================================================================  !
!
      implicit none

!  ---  inputs:
      integer, intent(in) :: NLAY, me, imp_physics

      real (kind=kind_phys), intent(in) :: si(:)

!  ---  outputs: (none)

!  ---  locals:
      integer :: k, kl, ier

!
!===> ...  begin here
!
!  ---  set up module variables

      if (me == 0) print *, VTAGCLD      !print out version tag

      if ( icldflg == 0 ) then
        print *,' - Diagnostic Cloud Method has been discontinued'
        stop

      else
        if (me == 0) then
          print *,' - Using Prognostic Cloud Method'
          if (imp_physics == 99) then
            print *,'   --- Zhao/Carr/Sundqvist microphysics'
          elseif (imp_physics == 98) then
            print *,'   --- zhao/carr/sundqvist + pdf cloud'
          elseif (imp_physics == 11) then
            print *,'   --- GFDL Lin cloud microphysics'
          elseif (imp_physics == 8) then
            print *,'   --- Thompson cloud microphysics'
          elseif (imp_physics == 6) then
            print *,'   --- WSM6 cloud microphysics'
          elseif (imp_physics == 10) then
            print *,'   --- MG cloud microphysics'
          elseif (imp_physics == 15) then
            print *,'   --- Ferrier-Aligo cloud microphysics'
          elseif (imp_physics == 17) then
            print *,'   --- NSSL cloud microphysics'
          else
            print *,'  !!! ERROR in cloud microphysc specification!!!', &
     &              '  imp_physics (NP3D) =',imp_physics
            stop
          endif
        endif
      endif

!> - Compute the top of BL cld (llyr), which is the topmost non
!!    cld(low) layer for stratiform (at or above lowest 0.1 of the
!!     atmosphere).

      if ( ivflip == 0 ) then    ! data from toa to sfc
        lab_do_k0 : do k = NLAY, 2, -1
          kl = k
          if (si(k) < 0.9e0) exit lab_do_k0
        enddo  lab_do_k0

        llyr = kl
      else                      ! data from sfc to top
        lab_do_k1 : do k = 2, NLAY
          kl = k
          if (si(k) < 0.9e0) exit lab_do_k1
        enddo  lab_do_k1

        llyr = kl - 1
      endif                     ! end_if_ivflip

!
      return
!...................................
      end subroutine cld_init
!! @}
!-----------------------------------

!> \ingroup module_radiation_clouds
!> Subroutine radiation_clouds_prop computes cloud related quantities
!! for different cloud microphysics schemes.
!>\section radiation_clouds_prop General Algorithm
!> @{
      subroutine radiation_clouds_prop                                  &
     &     ( plyr, plvl, tlyr, tvly, qlyr, qstl, rhly,                  &    !  ---  inputs:
     &       ccnd, ncndl, cnvw, cnvc, tracer1,                          &
     &       xlat, xlon, slmsk, dz, delp, IX, LM, NLAY, NLP1,           &
     &       deltaq, sup, me, icloud, kdt,                              &
     &       ntrac, ntcw, ntiw, ntrw, ntsw, ntgl, ntclamt,              &
     &       imp_physics, imp_physics_nssl, imp_physics_fer_hires,      &
     &       imp_physics_gfdl, imp_physics_thompson, imp_physics_wsm6,  &
     &       imp_physics_zhao_carr, imp_physics_zhao_carr_pdf,          &
     &       imp_physics_mg, iovr_rand, iovr_maxrand, iovr_max,         &
     &       iovr_dcorr, iovr_exp, iovr_exprand, idcor_con,             &
     &       idcor_hogan, idcor_oreopoulos,                             &
     &       imfdeepcnv, imfdeepcnv_gf, do_mynnedmf, lgfdlmprad,        &
     &       uni_cld, lmfshal, lmfdeep2, cldcov, clouds1,               &
     &       effrl, effri, effrr, effrs, effr_in,                       &
     &       effrl_inout, effri_inout, effrs_inout,                     &
     &       lwp_ex, iwp_ex, lwp_fc, iwp_fc,                            &
     &       dzlay, latdeg, julian, yearlen, gridkm,                    &
     &       cld_frac, cld_lwp, cld_reliq, cld_iwp, cld_reice,          &    !  ---  outputs:
     &       cld_rwp, cld_rerain, cld_swp, cld_resnow,                  &    
     &       clds, mtop, mbot, de_lgth, alpha                           &    
     &      )

! =================   subprogram documentation block   ================ !
!                                                                       !
! subprogram:    radiation_clouds_prop    computes cloud related quantities using    !
!   zhao/moorthi's prognostic cloud microphysics scheme.                !
!                                                                       !
! abstract:  this program computes cloud fractions from cloud           !
!   condensates, calculates liquid/ice cloud droplet effective radius,  !
!   and computes the low, mid, high, total and boundary layer cloud     !
!   fractions and the vertical indices of low, mid, and high cloud      !
!   top and base.  the three vertical cloud domains are set up in the   !
!   initial subroutine "cld_init".                         !
!                                                                       !
! usage:         call radiation_clouds_prop                             !
!                                                                       !
! subprograms called:                                                   !
!                                                                       !
!       'progcld_zhao_carr'      --- zhao/moorthi prognostic cloud scheme      !
!       'progcld_zhao_carr_pdf'  --- zhao/moorthi prognostic cloud + pdfcld    !
!       'progcld_gfdl_lin'       --- GFDL-Lin cloud microphysics               !
!       'progcld_fer_hires'      --- Ferrier-Aligo cloud microphysics          !
!       'progcld_thompson_wsm6'  --- Thompson/wsm6 cloud microphysics (EMC)    !
!       'progclduni'             --- MG cloud microphysics                     !
!                                --- GFDL cloud microphysics (EMC)             !
!                                --- Thompson + MYNN PBL (or GF convection)    !
!       'progcld_thompson'       --- Thompson MP (added by G. Thompson)        !
!       'gethml'                 --- get diagnostic hi, mid, low clouds        !
!                                                                       !
! attributes:                                                           !
!   language:   fortran 90                                              !
!   machine:    ibm-sp, sgi                                             !
!                                                                       !
!                                                                       !
!  ====================  definition of variables  ====================  !
!                                                                       !
! input variables:                                                      !
!   plyr  (IX,NLAY) : model layer mean pressure in mb (100Pa)           !
!   plvl  (IX,NLP1) : model level pressure in mb (100Pa)                !
!   tlyr  (IX,NLAY) : model layer mean temperature in k                 !
!   tvly  (IX,NLAY) : model layer virtual temperature in k              !
!   qlyr  (IX,NLAY) : layer specific humidity in gm/gm                  !
!   qstl  (IX,NLAY) : layer saturate humidity in gm/gm                  !
!   rhly  (IX,NLAY) : layer relative humidity (=qlyr/qstl)              !
!   ccnd  (IX,NLAY,ncndl) : layer cloud condensate amount               !
!                          water, ice, rain, snow (+ graupel)           !
!   ncndl           : number of layer cloud condensate types (max of 4) !
!   cnvw  (IX,NLAY) : layer convective cloud condensate                 !
!   cnvc  (IX,NLAY) : layer convective cloud cover                      !
!   tracer1 (IX,NLAY,1:ntrac-1) : all tracers (except sphum)              !
!   xlat  (IX)      : grid latitude in radians, default to pi/2 -> -pi/2!
!                     range, otherwise see in-line comment              !
!   xlon  (IX)      : grid longitude in radians  (not used)             !
!   slmsk (IX)      : sea/land mask array (sea:0,land:1,sea-ice:2)      !
!   dz    (ix,nlay) : layer thickness (km)                              !
!   delp  (ix,nlay) : model layer pressure thickness in mb (100Pa)      !
!   IX              : horizontal dimention                              !
!   LM,NLAY,NLP1    : vertical layer/level dimensions                   !
!   deltaq     (ix,nlay), half total water distribution width           !
!   sup        supersaturation                                          !
!   me         print control flag                                       !
!   icloud          : cloud effect to the optical depth in radiation    !
!   kdt             : current time step index                           !
!   ntrac     number of tracers (Model%ntrac)                           !
!   ntcw      tracer index for cloud liquid water (Model%ntcw)          !
!   ntiw      tracer index for cloud ice water (Model%ntiw)             !
!   ntrw      tracer index for rain water (Model%ntrw)                  !
!   ntsw      tracer index for snow water (Model%ntsw)                  !
!   ntgl      tracer index for graupel (Model%ntgl)                     !
!   ntclamt   tracer index for cloud amount (Model%ntclamt)             !
!   imp_physics               : cloud microphysics scheme control flag  !
!   imp_physics_nssl          : NSSL microphysics                       !
!   imp_physics_fer_hires     : Ferrier-Aligo microphysics scheme       !
!   imp_physics_gfdl          : GFDL microphysics scheme                !
!   imp_physics_thompson      : Thompson microphysics scheme            !
!   imp_physics_wsm6          : WSMG     microphysics scheme            !
!   imp_physics_zhao_carr     : Zhao-Carr microphysics scheme           !
!   imp_physics_zhao_carr_pdf : Zhao-Carr microphysics scheme with PDF clouds
!   imp_physics_mg  :  Morrison-Gettelman microphysics scheme           !
!   iovr_rand       :  choice of cloud-overlap: random (=0)
!   iovr_maxrand    :  choice of cloud-overlap: maximum random (=1)
!   iovr_max        :  choice of cloud-overlap: maximum (=2)
!   iovr_dcorr      :  choice of cloud-overlap: decorrelation length (=3)
!   iovr_exp        :  choice of cloud-overlap: exponential (=4)
!   iovr_exprand    :  choice of cloud-overlap: exponential random (=5)
!   idcor_con       :  choice for decorrelation-length: Use constant value (=0)
!   idcor_hogan     :  choice for decorrelation-length: (=1)
!   idcor_oreopoulos:  choice for decorrelation-length: (=2)
!   imfdeepcnv      :  flag for mass-flux deep convection scheme        !
!   imfdeepcnv_gf   :  flag for scale- & aerosol-aware Grell-Freitas scheme (GSD)
!   do_mynnedmf     :  flag for MYNN-EDMF                               !
!   lgfdlmprad      :  flag for GFDLMP radiation interaction            !
!   uni_cld         : logical - true for cloud fraction from shoc       !
!   lmfshal         : logical - true for mass flux shallow convection   !
!   lmfdeep2        : logical - true for mass flux deep convection      !
!   cldcov          : layer cloud fraction (used when uni_cld=.true.    !
!   clouds1         : layer total cloud fraction
!   effrl,          : effective radius for liquid water
!   effri,          : effective radius for ice water
!   effrr,          : effective radius for rain water
!   effrs,          : effective radius for snow water
!   effr_in,        : flag to use effective radii of cloud species in radiation
!   effrl_inout,    : eff. radius of cloud liquid water particle
!   effri_inout,    : eff. radius of cloud ice water particle
!   effrs_inout     : effective radius of cloud snow particle
!   lwp_ex          : total liquid water path from explicit microphysics
!   iwp_ex          : total ice water path from explicit microphysics
!   lwp_fc          : total liquid water path from cloud fraction scheme
!   iwp_fc          : total ice water path from cloud fraction scheme
!   dzlay(ix,nlay)  : thickness between model layer centers (km)        !
!   latdeg(ix)      : latitude (in degrees 90 -> -90)                   !
!   julian          : day of the year (fractional julian day)           !
!   yearlen         : current length of the year (365/366 days)         !
!   gridkm          : grid length in km
!                                                                       !
! output variables:                                                     !
!   cloud profiles:                                                     !
!      cld_frac  (:,:) - layer total cloud fraction                     !
!      cld_lwp   (:,:) - layer cloud liq water path       (g/m**2)      !
!      cld_reliq (:,:) - mean eff radius for liq cloud    (micron)      !
!      cld_iwp   (:,:) - layer cloud ice water path       (g/m**2)      !
!      cld_reice (:,:) - mean eff radius for ice cloud    (micron)      !
!      cld_rwp   (:,:) - layer rain drop water path       not assigned  !
!      cld_rerain(:,:) - mean eff radius for rain drop    (micron)      !
!  *** cld_swp   (:,:) - layer snow flake water path      not assigned  !
!      cld_resnow(:,:) - mean eff radius for snow flake   (micron)      !
!  *** fu's scheme need to be normalized by snow density (g/m**3/1.0e6) !
!   clds  (IX,5)    : fraction of clouds for low, mid, hi, tot, bl      !
!   mtop  (IX,3)    : vertical indices for low, mid, hi cloud tops      !
!   mbot  (IX,3)    : vertical indices for low, mid, hi cloud bases     !
!   de_lgth(ix)     : clouds decorrelation length (km)                  !
!   alpha(ix,nlay)  : alpha decorrelation parameter
!                                                                       !
! module variables:                                                     !
!   ivflip          : control flag of vertical index direction          !
!                     =0: index from toa to surface                     !
!                     =1: index from surface to toa                     !
!   lmfshal         : mass-flux shallow conv scheme flag                !
!   lmfdeep2        : scale-aware mass-flux deep conv scheme flag       !
!   lcrick          : control flag for eliminating CRICK                !
!                     =t: apply layer smoothing to eliminate CRICK      !
!                     =f: do not apply layer smoothing                  !
!   lcnorm          : control flag for in-cld condensate                !
!                     =t: normalize cloud condensate                    !
!                     =f: not normalize cloud condensate                !
!                                                                       !
!  ====================    end of description    =====================  !
      implicit none

!  ---  inputs
      integer,  intent(in) :: IX, LM, NLAY, NLP1, me, ncndl, icloud
      integer,  intent(in) :: ntrac, ntcw, ntiw, ntrw, ntsw, ntgl,      &
     &                        ntclamt
      integer,  intent(in) :: kdt, imfdeepcnv, imfdeepcnv_gf
      integer,  intent(in) ::                                           &
     &     imp_physics,                 ! Flag for MP scheme
     &     imp_physics_nssl,            ! Flag for NSSL scheme
     &     imp_physics_fer_hires,       ! Flag for fer-hires scheme
     &     imp_physics_gfdl,            ! Flag for gfdl scheme
     &     imp_physics_thompson,        ! Flag for thompsonscheme
     &     imp_physics_wsm6,            ! Flag for wsm6 scheme
     &     imp_physics_zhao_carr,       ! Flag for zhao-carr scheme
     &     imp_physics_zhao_carr_pdf,   ! Flag for zhao-carr+PDF scheme
     &     imp_physics_mg               ! Flag for MG scheme

      integer,              intent(in)  ::                               &
     &     iovr_rand,                    ! Flag for random cloud overlap method
     &     iovr_maxrand,                 ! Flag for maximum-random cloud overlap method
     &     iovr_max,                     ! Flag for maximum cloud overlap method
     &     iovr_dcorr,                   ! Flag for decorrelation-length cloud overlap method
     &     iovr_exp,                     ! Flag for exponential cloud overlap method
     &     iovr_exprand,                 ! Flag for exponential-random cloud overlap method
     &     idcor_con,                   
     &     idcor_hogan,                 
     &     idcor_oreopoulos


      logical, intent(in)  :: uni_cld, lmfshal, lmfdeep2, effr_in
      logical, intent(in)  :: do_mynnedmf, lgfdlmprad

      real (kind=kind_phys), dimension(:,:,:), intent(in) :: ccnd,      &
     &                                                       tracer1
      real (kind=kind_phys), dimension(:,:), intent(in) :: plvl, plyr,  &
     &       tlyr,  tvly,  qlyr,  qstl, rhly, cnvw, cnvc, cldcov,       &
     &       delp, dz, effrl, effri, effrr, effrs, dzlay, clouds1

      real (kind=kind_phys), intent(in) :: sup
      real (kind=kind_phys), dimension(:),   intent(in) :: xlat, xlon,  &
     &       slmsk

      real(kind=kind_phys), dimension(:), intent(in) :: latdeg, gridkm
      real(kind=kind_phys), intent(in) :: julian
      integer, intent(in)              :: yearlen

!  ---  inout
      real(kind=kind_phys),dimension(:,:) :: deltaq
      real(kind=kind_phys),dimension(:,:),intent(inout) ::               &
     &       effrl_inout, effri_inout, effrs_inout
      real(kind=kind_phys), dimension(:), intent(inout) ::               &
     &      lwp_ex, iwp_ex, lwp_fc, iwp_fc

!  ---  outputs

      real (kind=kind_phys), dimension(:,:),   intent(out) ::            &
     &   cld_frac, cld_lwp, cld_reliq, cld_iwp, cld_reice,               &
     &   cld_rwp, cld_rerain, cld_swp, cld_resnow
      real (kind=kind_phys), dimension(:,:),   intent(out) :: clds
      real (kind=kind_phys), dimension(:),     intent(out) :: de_lgth
      real (kind=kind_phys), dimension(:,:),   intent(out) :: alpha

      integer,               dimension(:,:),   intent(out) :: mtop,mbot

!  ---  local variables:
      real (kind=kind_phys), dimension(IX,NLAY) :: cldtot, cldcnv,      &
     &       cwp, cip, crp, csp, rew, rei, res, rer, tem2d, clwf

      real (kind=kind_phys) :: ptop1(IX,NK_CLDS+1), rxlat(ix)

      real (kind=kind_phys) :: clwmin, clwm, clwt, onemrh, value,       &
     &       tem1, tem2, tem3

      integer :: i, k, id, nf

!  ---  constant values
!     real (kind=kind_phys), parameter :: xrc3 = 200.
      real (kind=kind_phys), parameter :: xrc3 = 100.

!
!===> ... begin here
!
      if (me == 0 .and. kdt == 1) then                                   &
          print*, 'in radiation_clouds_prop=', imp_physics, uni_cld,     &
     &           ncndl, lgfdlmprad, do_mynnedmf, imfdeepcnv, kdt
      end if

      do k = 1, NLAY
        do i = 1, IX
          cld_frac(i,k)   = 0.0
          cld_lwp(i,k)    = 0.0
          cld_reliq(i,k)  = 0.0
          cld_iwp(i,k)    = 0.0
          cld_reice(i,k)  = 0.0
          cld_rwp(i,k)    = 0.0
          cld_rerain(i,k) = 0.0
          cld_swp(i,k)    = 0.0
          cld_resnow(i,k) = 0.0
        enddo
      enddo

      do k = 1, NLAY
        do i = 1, IX
            cldtot(i,k) = 0.0
            cldcnv(i,k) = 0.0
        end do
      end do

      if (imp_physics == imp_physics_zhao_carr .or.                     &
     &    imp_physics == imp_physics_mg) then ! zhao/moorthi's p
                  ! or unified cloud and/or with MG microphysics

        if (uni_cld .and. ncndl >= 2) then
          call progclduni (plyr, plvl, tlyr, tvly, ccnd, ncndl,         & !  ---  inputs
     &                     xlat, xlon, slmsk, dz, delp,                 &
     &                     IX, NLAY, NLP1, cldcov,                      &
     &                     effrl, effri, effrr, effrs, effr_in,         &
     &                     dzlay,                                       & 
     &                     cldtot, cldcnv,                              & ! inout
     &                     cld_frac, cld_lwp, cld_reliq, cld_iwp,       & !  ---  outputs
     &                     cld_reice,cld_rwp, cld_rerain,cld_swp,       &  
     &                     cld_resnow)
        else
          call progcld_zhao_carr (plyr ,plvl, tlyr, tvly, qlyr,         & !  ---  inputs
     &                    qstl, rhly, ccnd(1:IX,1:NLAY,1), xlat, xlon,  &
     &                    slmsk, dz, delp, IX, NLAY, NLP1, uni_cld,     &
     &                    lmfshal, lmfdeep2,                            &
     &                    cldcov, effrl, effri, effrr, effrs, effr_in,  &
     &                    dzlay,                                        &
     &                    cldtot, cldcnv,                               & ! inout
     &                    cld_frac, cld_lwp, cld_reliq, cld_iwp,        & !  ---  outputs
     &                    cld_reice,cld_rwp, cld_rerain,cld_swp,        & 
     &                    cld_resnow)
        endif

      elseif(imp_physics == imp_physics_zhao_carr_pdf) then      ! zhao/moorthi's prognostic cloud+pdfcld

        call progcld_zhao_carr_pdf (plyr, plvl, tlyr, tvly, qlyr,       &  !  ---  inputs
     &                 qstl, rhly, ccnd(1:IX,1:NLAY,1), cnvw, cnvc,     &
     &                 xlat, xlon, slmsk, dz, delp, IX, NLAY, NLP1,     &
     &                 deltaq, sup, kdt, me, dzlay,                     & 
     &                 cldtot, cldcnv,                                  &  ! inout
     &                 cld_frac, cld_lwp, cld_reliq, cld_iwp,           &  !  ---  outputs
     &                 cld_reice,cld_rwp, cld_rerain,cld_swp,           & 
     &                 cld_resnow)

      elseif (imp_physics == imp_physics_gfdl) then           ! GFDL cloud scheme

        if (.not. lgfdlmprad) then
          call progcld_gfdl_lin (plyr, plvl, tlyr, tvly, qlyr,          &    !  ---  inputs
     &                    qstl, rhly, ccnd(1:IX,1:NLAY,1), cnvw, cnvc,  &
     &                    xlat, xlon, slmsk, cldcov, dz, delp,          &
     &                    IX, NLAY, NLP1, dzlay,                        &
     &                    cldtot, cldcnv,                               &  ! inout
     &                    cld_frac, cld_lwp, cld_reliq, cld_iwp,        &  !  ---  outputs
     &                    cld_reice,cld_rwp, cld_rerain,cld_swp,        &
     &                    cld_resnow)
        else

          call progclduni (plyr, plvl, tlyr, tvly, ccnd, ncndl, xlat,   &    !  ---  inputs
     &                   xlon, slmsk, dz,delp, IX, NLAY, NLP1, cldcov,  &
     &                   effrl, effri, effrr, effrs, effr_in,           &
     &                   dzlay,                                         &
     &                   cldtot, cldcnv,                                &  ! inout
     &                   cld_frac, cld_lwp, cld_reliq, cld_iwp,         & !  ---  outputs
     &                   cld_reice,cld_rwp, cld_rerain,cld_swp,         & 
     &                   cld_resnow)
        endif


      elseif(imp_physics == imp_physics_fer_hires) then
          if (kdt == 1) then
            effrl_inout(:,:) = 10.
            effri_inout(:,:) = 50.
            effrs_inout(:,:) = 250.
          endif

          call progcld_fer_hires (plyr,plvl,tlyr,tvly,qlyr,qstl,rhly,   &  !  --- inputs
     &                    tracer1,xlat,xlon,slmsk,dz,delp,              &
     &                    ntrac-1, ntcw-1,ntiw-1,ntrw-1,                &
     &                    IX,NLAY,NLP1, icloud, uni_cld,                &
     &                    lmfshal, lmfdeep2,                            &
     &                    cldcov(:,1:NLAY),effrl_inout(:,:),            &
     &                    effri_inout(:,:), effrs_inout(:,:),           &
     &                    dzlay,                                        &
     &                    cldtot, cldcnv,                               &  ! inout
     &                    cld_frac, cld_lwp, cld_reliq, cld_iwp,        & !  ---  outputs
     &                    cld_reice,cld_rwp, cld_rerain,cld_swp,        & 
     &                    cld_resnow)

        elseif ( imp_physics == imp_physics_nssl ) then                              ! NSSL MP

          if(do_mynnedmf .or. imfdeepcnv == imfdeepcnv_gf ) then ! MYNN PBL or GF conv
              !-- MYNN PBL or convective GF
              !-- use cloud fractions with SGS clouds
              do k=1,NLAY
                do i=1,IX
                  cld_frac(i,k)  = clouds1(i,k)
                enddo
              enddo

                ! --- use clduni with the NSSL microphysics.
                ! --- make sure that effr_in=.true. in the input.nml!
                call progclduni (plyr, plvl, tlyr, tvly, ccnd, ncndl,   & !  ---  inputs
     &                   xlat, xlon, slmsk, dz, delp, IX, NLAY, NLP1,   &
     &                   cld_frac,                                      &
     &                   effrl, effri, effrr, effrs, effr_in ,          &
     &                   dzlay,                                         &
     &                   cldtot, cldcnv,                                &  ! inout
     &                   cld_frac, cld_lwp, cld_reliq, cld_iwp,         & !  ---  outputs
     &                   cld_reice,cld_rwp, cld_rerain,cld_swp,         &
     &                   cld_resnow)
          else
            ! MYNN PBL or GF convective are not used
              call progcld_thompson_wsm6 (plyr,plvl,tlyr,qlyr,qstl,     & !  --- inputs
     &                   rhly,tracer1,xlat,xlon,slmsk,dz,delp,          &
     &                   ntrac-1, ntcw-1,ntiw-1,ntrw-1,                 &
     &                   ntsw-1,ntgl-1,                                 &
     &                   IX, NLAY, NLP1, uni_cld, lmfshal, lmfdeep2,    &
     &                   cldcov(:,1:NLAY), cnvw, effrl_inout,           &
     &                   effri_inout, effrs_inout,                      &
     &                   lwp_ex, iwp_ex, lwp_fc, iwp_fc,                &
     &                   dzlay,                                         &
     &                   cldtot, cldcnv,                                &  ! inout
     &                   cld_frac, cld_lwp, cld_reliq, cld_iwp,         & !  ---  outputs
     &                   cld_reice,cld_rwp, cld_rerain,cld_swp,         &
     &                   cld_resnow)
          endif ! MYNN PBL or GF

        elseif(imp_physics == imp_physics_thompson) then                              ! Thompson MP

          if(do_mynnedmf .or. imfdeepcnv == imfdeepcnv_gf ) then ! MYNN PBL or GF conv

            if (icloud == 3) then
              call progcld_thompson (plyr,plvl,tlyr,qlyr,qstl,rhly,     & !  --- inputs
     &                    tracer1,xlat,xlon,slmsk,dz,delp,              &
     &                    ntrac-1, ntcw-1,ntiw-1,ntrw-1,                &
     &                    ntsw-1,ntgl-1,                                &
     &                    IX, LM, NLP1, uni_cld, lmfshal, lmfdeep2,     &
     &                    cldcov(:,1:LM), effrl, effri, effrs,          &
     &                    lwp_ex, iwp_ex, lwp_fc, iwp_fc,               &
     &                    dzlay,  gridkm,                               &
     &                    cldtot, cldcnv,                               &  ! inout
     &                    cld_frac, cld_lwp, cld_reliq, cld_iwp,        & !  ---  outputs
     &                    cld_reice,cld_rwp, cld_rerain,cld_swp,        & 
     &                    cld_resnow)
            else

              !-- MYNN PBL or convective GF
              !-- use cloud fractions with SGS clouds
              do k=1,NLAY
                do i=1,IX
                  cld_frac(i,k)  = clouds1(i,k)
                enddo
              enddo

                ! --- use clduni as with the GFDL microphysics.
                ! --- make sure that effr_in=.true. in the input.nml!
                call progclduni (plyr, plvl, tlyr, tvly, ccnd, ncndl,   & !  ---  inputs
     &                   xlat, xlon, slmsk, dz, delp, IX, NLAY, NLP1,   &
     &                   cld_frac,                                      &
     &                   effrl, effri, effrr, effrs, effr_in ,          &
     &                   dzlay,                                         &
     &                   cldtot, cldcnv,                                &  ! inout
     &                   cld_frac, cld_lwp, cld_reliq, cld_iwp,         & !  ---  outputs
     &                   cld_reice,cld_rwp, cld_rerain,cld_swp,         & 
     &                   cld_resnow)
            endif

          else
            ! MYNN PBL or GF convective are not used

            if (icloud == 3) then
              call progcld_thompson (plyr,plvl,tlyr,qlyr,qstl,rhly,     & !  --- inputs
     &                   tracer1,xlat,xlon,slmsk,dz,delp,               &
     &                   ntrac-1, ntcw-1,ntiw-1,ntrw-1,                 &
     &                   ntsw-1,ntgl-1,                                 &
     &                   IX, LM, NLP1, uni_cld, lmfshal, lmfdeep2,      &
     &                   cldcov(:,1:LM), effrl, effri, effrs,           &
     &                   lwp_ex, iwp_ex, lwp_fc, iwp_fc,                &
     &                   dzlay,  gridkm,                                &
     &                   cldtot, cldcnv,                                &  ! inout
     &                   cld_frac, cld_lwp, cld_reliq, cld_iwp,         & !  ---  outputs
     &                   cld_reice,cld_rwp, cld_rerain,cld_swp,         & 
     &                   cld_resnow)

            else
              call progcld_thompson_wsm6 (plyr,plvl,tlyr,qlyr,qstl,     & !  --- inputs
     &                   rhly,tracer1,xlat,xlon,slmsk,dz,delp,          &
     &                   ntrac-1, ntcw-1,ntiw-1,ntrw-1,                 &
     &                   ntsw-1,ntgl-1,                                 &
     &                   IX, NLAY, NLP1, uni_cld, lmfshal, lmfdeep2,    &
     &                   cldcov(:,1:NLAY), cnvw, effrl, effri, effrs,   &
     &                   lwp_ex, iwp_ex, lwp_fc, iwp_fc,                &
     &                   dzlay,                                         &
     &                   cldtot, cldcnv,                                &  ! inout
     &                   cld_frac, cld_lwp, cld_reliq, cld_iwp,         & !  ---  outputs
     &                   cld_reice,cld_rwp, cld_rerain,cld_swp,         & 
     &                   cld_resnow)
            endif
          endif ! MYNN PBL or GF

        endif                            ! end if_imp_physics

!> - Compute SFC/low/middle/high cloud top pressure for each cloud
!! domain for given latitude.
!     ptopc(k,i): top presure of each cld domain (k=1-4 are sfc,L,m,h;
!  ---  i=1,2 are low-lat (<45 degree) and pole regions)

      do i =1, IX
        rxlat(i) = abs( xlat(i) / con_pi )      ! if xlat in pi/2 -> -pi/2 range
!       rxlat(i) = abs(0.5 - xlat(i)/con_pi)    ! if xlat in 0 -> pi range
      enddo

      do id = 1, 4
        tem1 = ptopc(id,2) - ptopc(id,1)

        do i =1, IX
          ptop1(i,id) = ptopc(id,1) + tem1*max( 0.0, 4.0*rxlat(i)-1.0 )
        enddo
      enddo
        
      ! Compute cloud decorrelation length
      if (idcor == idcor_hogan) then
        call cmp_dcorr_lgth(ix, xlat, con_pi, de_lgth)
      endif
      if (idcor == idcor_oreopoulos) then
        call cmp_dcorr_lgth(ix, latdeg, julian, yearlen, de_lgth)
      endif
      if (idcor == idcor_con) then
         de_lgth(:) = decorr_con
      endif

      ! Call subroutine get_alpha_exper to define alpha parameter for exponential cloud overlap options
      if ( iovr == iovr_dcorr .or. iovr == iovr_exp                      &
     &     .or. iovr == iovr_exprand) then
         call get_alpha_exper(ix, nLay, iovr, iovr_exprand, dzlay,       &
     &                        de_lgth, cld_frac, alpha)
      else
         de_lgth(:) = 0.
         alpha(:,:) = 0.
      endif

!> - Call gethml() to compute low,mid,high,total, and boundary layer
!!    cloud fractions and clouds top/bottom layer indices for low, mid,
!!    and high clouds.
!  ---  compute low, mid, high, total, and boundary layer cloud fractions
!       and clouds top/bottom layer indices for low, mid, and high clouds.
!       The three cloud domain boundaries are defined by ptopc.  The cloud
!       overlapping method is defined by control flag 'iovr', which may
!       be different for lw and sw radiation programs.

      call gethml                                                       &
!  ---  inputs:
     &     ( plyr, ptop1, cldtot, cldcnv, dz, de_lgth, alpha,           &
     &       IX, NLAY, iovr_rand, iovr_maxrand, iovr_max,               &
     &       iovr_dcorr, iovr_exp, iovr_exprand,                        &
!  ---  outputs:
     &       clds, mtop, mbot                                           &
     &     )

      return
!...................................
      end subroutine radiation_clouds_prop

!> \ingroup module_radiation_clouds
!> This subroutine computes cloud related quantities using
!! zhao/moorthi's prognostic cloud microphysics scheme.
!>\section progcld_zhao_carr General Algorithm
!> @{
      subroutine progcld_zhao_carr                                      &
     &     ( plyr,plvl,tlyr,tvly,qlyr,qstl,rhly,clw,                    &    !  ---  inputs:
     &       xlat,xlon,slmsk,dz,delp, IX, NLAY, NLP1,                   &
     &       uni_cld, lmfshal, lmfdeep2, cldcov,                        &
     &       effrl,effri,effrr,effrs,effr_in,                           &
     &       dzlay, cldtot, cldcnv,                                     &
     &       cld_frac, cld_lwp, cld_reliq, cld_iwp,                     & !  ---  outputs
     &       cld_reice,cld_rwp, cld_rerain,cld_swp, cld_resnow          &
     &      )

! =================   subprogram documentation block   ================ !
!                                                                       !
! subprogram:    progcld_zhao_carr    computes cloud related quantities using    !
!   zhao/moorthi's prognostic cloud microphysics scheme.                !
!                                                                       !
! abstract:  this program computes cloud fractions from cloud           !
!   condensates, calculates liquid/ice cloud droplet effective radius,  !
!   and computes the low, mid, high, total and boundary layer cloud     !
!   fractions and the vertical indices of low, mid, and high cloud      !
!   top and base.  the three vertical cloud domains are set up in the   !
!   initial subroutine "cld_init".                                      !
!                                                                       !
! usage:         call progcld_zhao_carr                                          !
!                                                                       !
! subprograms called:   gethml                                          !
!                                                                       !
! attributes:                                                           !
!   language:   fortran 90                                              !
!   machine:    ibm-sp, sgi                                             !
!                                                                       !
!                                                                       !
!  ====================  definition of variables  ====================  !
!                                                                       !
! input variables:                                                      !
!   plyr  (IX,NLAY) : model layer mean pressure in mb (100Pa)           !
!   plvl  (IX,NLP1) : model level pressure in mb (100Pa)                !
!   tlyr  (IX,NLAY) : model layer mean temperature in k                 !
!   tvly  (IX,NLAY) : model layer virtual temperature in k              !
!   qlyr  (IX,NLAY) : layer specific humidity in gm/gm                  !
!   qstl  (IX,NLAY) : layer saturate humidity in gm/gm                  !
!   rhly  (IX,NLAY) : layer relative humidity (=qlyr/qstl)              !
!   clw   (IX,NLAY) : layer cloud condensate amount                     !
!   xlat  (IX)      : grid latitude in radians, default to pi/2 -> -pi/2!
!                     range, otherwise see in-line comment              !
!   xlon  (IX)      : grid longitude in radians  (not used)             !
!   slmsk (IX)      : sea/land mask array (sea:0,land:1,sea-ice:2)      !
!   dz    (ix,nlay) : layer thickness (km)                              !
!   delp  (ix,nlay) : model layer pressure thickness in mb (100Pa)      !
!   IX              : horizontal dimention                              !
!   NLAY,NLP1       : vertical layer/level dimensions                   !
!   uni_cld         : logical - true for cloud fraction from shoc       !
!   lmfshal         : logical - true for mass flux shallow convection   !
!   lmfdeep2        : logical - true for mass flux deep convection      !
!   cldcov          : layer cloud fraction (used when uni_cld=.true.    !
!   effrl           : effective radius for liquid water
!   effri           : effective radius for ice water
!   effrr           : effective radius for rain water
!   effrs           : effective radius for snow water
!   effr_in         : logical, if .true. use input effective radii
!   dzlay(ix,nlay)  : thickness between model layer centers (km)        !
!                                                                       !
! output variables:                                                     !
!   cloud profiles:                                                     !
!      cld_frac  (:,:) - layer total cloud fraction                     !
!      cld_lwp   (:,:) - layer cloud liq water path       (g/m**2)      !
!      cld_reliq (:,:) - mean eff radius for liq cloud    (micron)      !
!      cld_iwp   (:,:) - layer cloud ice water path       (g/m**2)      !
!      cld_reice (:,:) - mean eff radius for ice cloud    (micron)      !
!      cld_rwp   (:,:) - layer rain drop water path       not assigned  !
!      cld_rerain(:,:) - mean eff radius for rain drop    (micron)      !
!  *** cld_swp   (:,:) - layer snow flake water path      not assigned  !
!      cld_resnow(:,:) - mean eff radius for snow flake   (micron)      !
!                                                                       !
! module variables:                                                     !
!   ivflip          : control flag of vertical index direction          !
!                     =0: index from toa to surface                     !
!                     =1: index from surface to toa                     !
!   lmfshal         : mass-flux shallow conv scheme flag                !
!   lmfdeep2        : scale-aware mass-flux deep conv scheme flag       !
!   lcrick          : control flag for eliminating CRICK                !
!                     =t: apply layer smoothing to eliminate CRICK      !
!                     =f: do not apply layer smoothing                  !
!   lcnorm          : control flag for in-cld condensate                !
!                     =t: normalize cloud condensate                    !
!                     =f: not normalize cloud condensate                !
!                                                                       !
!  ====================    end of description    =====================  !
!
      implicit none

!  ---  inputs
      integer,  intent(in) :: IX, NLAY, NLP1

      logical, intent(in)  :: uni_cld, lmfshal, lmfdeep2, effr_in

      real (kind=kind_phys), dimension(:,:), intent(in) :: plvl, plyr,  &
     &       tlyr,  tvly,  qlyr,  qstl, rhly, clw, cldcov, delp, dz,    &
     &       effrl, effri, effrr, effrs, dzlay

      real (kind=kind_phys), dimension(:),   intent(in) :: xlat, xlon,  &
     &       slmsk

!  --- inputs/outputs

      real (kind=kind_phys), dimension(:,:), intent(inout) ::            &
     &   cld_frac, cld_lwp, cld_reliq, cld_iwp, cld_reice,               &
     &   cld_rwp, cld_rerain, cld_swp, cld_resnow

!  ---  local variables:
      real (kind=kind_phys), dimension(IX,NLAY) :: cldtot, cldcnv,      &
     &       cwp, cip, crp, csp, rew, rei, res, rer, tem2d, clwf

      real (kind=kind_phys) :: clwmin, clwm, clwt, onemrh, value,       &
     &       tem1, tem2, tem3

      integer :: i, k, id, nf

!  ---  constant values
!     real (kind=kind_phys), parameter :: xrc3 = 200.
      real (kind=kind_phys), parameter :: xrc3 = 100.

!
!===> ... begin here
!
!> - Assgin liquid/ice/rain/snow cloud effective radius from input or predefined values.
      if(effr_in) then
        do k = 1, NLAY
          do i = 1, IX
            cldtot(i,k) = 0.0
            cldcnv(i,k) = 0.0
            cwp   (i,k) = 0.0
            cip   (i,k) = 0.0
            crp   (i,k) = 0.0
            csp   (i,k) = 0.0
            rew   (i,k) = effrl (i,k)
            rei   (i,k) = effri (i,k)
            rer   (i,k) = effrr (i,k)
            res   (i,k) = effrs (i,k)
            tem2d (i,k) = min(1.0, max(0.0,(con_ttp-tlyr(i,k))*0.05))
            clwf(i,k)   = 0.0
          enddo
        enddo
      else
        do k = 1, NLAY
          do i = 1, IX
            cldtot(i,k) = 0.0
            cldcnv(i,k) = 0.0
            cwp   (i,k) = 0.0
            cip   (i,k) = 0.0
            crp   (i,k) = 0.0
            csp   (i,k) = 0.0
            rew   (i,k) = reliq_def            ! default liq radius to 10 micron
            rei   (i,k) = reice_def            ! default ice radius to 50 micron
            rer   (i,k) = rrain_def            ! default rain radius to 1000 micron
            res   (i,k) = rsnow_def            ! default snow radius to 250 micron
            tem2d (i,k) = min(1.0, max(0.0, (con_ttp-tlyr(i,k))*0.05))
            clwf(i,k)   = 0.0
          enddo
        enddo
      endif
!
      if ( lcrick ) then
        do i = 1, IX
          clwf(i,1)    = 0.75*clw(i,1)    + 0.25*clw(i,2)
          clwf(i,nlay) = 0.75*clw(i,nlay) + 0.25*clw(i,nlay-1)
        enddo
        do k = 2, NLAY-1
          do i = 1, IX
            clwf(i,K) = 0.25*clw(i,k-1) + 0.5*clw(i,k) + 0.25*clw(i,k+1)
          enddo
        enddo
      else
        do k = 1, NLAY
          do i = 1, IX
            clwf(i,k) = clw(i,k)
          enddo
        enddo
      endif

!> - Compute cloud liquid/ice condensate path in \f$ g/m^2 \f$ .

        do k = 1, NLAY
          do i = 1, IX
            clwt     = max(0.0, clwf(i,k)) * gfac * delp(i,k)
            cip(i,k) = clwt * tem2d(i,k)
            cwp(i,k) = clwt - cip(i,k)
          enddo
        enddo

!> - Compute effective liquid cloud droplet radius over land.

      if(.not. effr_in) then
        do i = 1, IX
          if (nint(slmsk(i)) == 1) then
            do k = 1, NLAY
              rew(i,k) = 5.0 + 5.0 * tem2d(i,k)
            enddo
          endif
        enddo
      endif

      if (uni_cld) then     ! use unified sgs clouds generated outside
        do k = 1, NLAY
          do i = 1, IX
            cldtot(i,k) = cldcov(i,k)
          enddo
        enddo

      else

!> - Compute layer cloud fraction.


        if (.not. lmfshal) then
          call cloud_fraction_XuRandall                                 &
     &      ( IX, NLAY, plyr, clwf, rhly, qstl,                         & !  ---  inputs
     &        cldtot )                                                  & !  ---  outputs 
        else
          call cloud_fraction_mass_flx_1                                &
     &      ( IX, NLAY, lmfdeep2, xrc3, plyr, clwf, rhly, qstl,         & !  ---  inputs
     &        cldtot ) 
        endif  

      endif                                ! if (uni_cld) then

      do k = 1, NLAY
        do i = 1, IX
          if (cldtot(i,k) < climit) then
            cldtot(i,k) = 0.0
            cwp(i,k)    = 0.0
            cip(i,k)    = 0.0
            crp(i,k)    = 0.0
            csp(i,k)    = 0.0
          endif
        enddo
      enddo

      if ( lcnorm ) then
        do k = 1, NLAY
          do i = 1, IX
            if (cldtot(i,k) >= climit) then
              tem1 = 1.0 / max(climit2, cldtot(i,k))
              cwp(i,k) = cwp(i,k) * tem1
              cip(i,k) = cip(i,k) * tem1
              crp(i,k) = crp(i,k) * tem1
              csp(i,k) = csp(i,k) * tem1
            endif
          enddo
        enddo
      endif

!> - Compute effective ice cloud droplet radius following Heymsfield
!!   and McFarquhar (1996) \cite heymsfield_and_mcfarquhar_1996.

      if(.not.effr_in) then
        do k = 1, NLAY
          do i = 1, IX
            tem2 = tlyr(i,k) - con_ttp

            if (cip(i,k) > 0.0) then
              tem3 = gord * cip(i,k) * plyr(i,k) / (delp(i,k)*tvly(i,k))

              if (tem2 < -50.0) then
                rei(i,k) = (1250.0/9.917) * tem3 ** 0.109
              elseif (tem2 < -40.0) then
                rei(i,k) = (1250.0/9.337) * tem3 ** 0.08
              elseif (tem2 < -30.0) then
                rei(i,k) = (1250.0/9.208) * tem3 ** 0.055
              else
                rei(i,k) = (1250.0/9.387) * tem3 ** 0.031
              endif
!             rei(i,k)   = max(20.0, min(rei(i,k), 300.0))
!             rei(i,k)   = max(10.0, min(rei(i,k), 100.0))
              rei(i,k)   = max(10.0, min(rei(i,k), 150.0))
!             rei(i,k)   = max(5.0,  min(rei(i,k), 130.0))
            endif
          enddo
        enddo
      endif

!
      do k = 1, NLAY
        do i = 1, IX
          cld_frac(i,k)   = cldtot(i,k)
          cld_lwp(i,k)    = cwp(i,k)
          cld_reliq(i,k)  = rew(i,k)
          cld_iwp(i,k)    = cip(i,k)
          cld_reice(i,k)  = rei(i,k)
!         cld_rwp(i,k)    = 0.0
          cld_rerain(i,k) = rer(i,k)
!         cld_swp(i,k)    = 0.0
          cld_resnow(i,k) = res(i,k)
        enddo
      enddo
!
      return
!...................................
      end subroutine progcld_zhao_carr
!-----------------------------------
!> @}
!-----------------------------------

!> \ingroup module_radiation_clouds
!> This subroutine computes cloud related quantities using
!! zhao/moorthi's prognostic cloud microphysics scheme + pdfcld.
!>\section progcld_zhao_carr_pdf General Algorithm
!! @{
      subroutine progcld_zhao_carr_pdf                                  &
     &     ( plyr,plvl,tlyr,tvly,qlyr,qstl,rhly,clw,cnvw,cnvc,          &    !  ---  inputs:
     &       xlat,xlon,slmsk, dz, delp,                                 &
     &       ix, nlay, nlp1,                                            &
     &       deltaq,sup,kdt,me,                                         &
     &       dzlay, cldtot, cldcnv,                                     &
     &       cld_frac, cld_lwp, cld_reliq, cld_iwp,                     & !  ---  outputs
     &       cld_reice,cld_rwp, cld_rerain,cld_swp, cld_resnow          &
     &      )

! =================   subprogram documentation block   ================ !
!                                                                       !
! subprogram:    progcld_zhao_carr_pdf    computes cloud related quantities using    !
!   zhao/moorthi's prognostic cloud microphysics scheme.                !
!                                                                       !
! abstract:  this program computes cloud fractions from cloud           !
!   condensates, calculates liquid/ice cloud droplet effective radius,  !
!   and computes the low, mid, high, total and boundary layer cloud     !
!   fractions and the vertical indices of low, mid, and high cloud      !
!   top and base.  the three vertical cloud domains are set up in the   !
!   initial subroutine "cld_init".                                      !
!                                                                       !
! usage:         call progcld_zhao_carr_pdf                                          !
!                                                                       !
! subprograms called:   gethml                                          !
!                                                                       !
! attributes:                                                           !
!   language:   fortran 90                                              !
!   machine:    ibm-sp, sgi                                             !
!                                                                       !
!                                                                       !
!  ====================  defination of variables  ====================  !
!                                                                       !
! input variables:                                                      !
!   plyr  (ix,nlay) : model layer mean pressure in mb (100pa)           !
!   plvl  (ix,nlp1) : model level pressure in mb (100pa)                !
!   tlyr  (ix,nlay) : model layer mean temperature in k                 !
!   tvly  (ix,nlay) : model layer virtual temperature in k              !
!   qlyr  (ix,nlay) : layer specific humidity in gm/gm                  !
!   qstl  (ix,nlay) : layer saturate humidity in gm/gm                  !
!   rhly  (ix,nlay) : layer relative humidity (=qlyr/qstl)              !
!   clw   (ix,nlay) : layer cloud condensate amount                     !
!   xlat  (ix)      : grid latitude in radians, default to pi/2 -> -pi/2!
!                     range, otherwise see in-line comment              !
!   xlon  (ix)      : grid longitude in radians  (not used)             !
!   slmsk (ix)      : sea/land mask array (sea:0,land:1,sea-ice:2)      !
!   dz    (ix,nlay) : layer thickness (km)                              !
!   delp  (ix,nlay) : model layer pressure thickness in mb (100Pa)      !
!   ix              : horizontal dimention                              !
!   nlay,nlp1       : vertical layer/level dimensions                   !
!   cnvw  (ix,nlay) : layer convective cloud condensate                 !
!   cnvc  (ix,nlay) : layer convective cloud cover                      !
!   deltaq(ix,nlay) : half total water distribution width               !
!   sup             : supersaturation                                   !
!   dzlay(ix,nlay)  : thickness between model layer centers (km)        !
!                                                                       !
! output variables:                                                     !
!   cloud profiles:                                                     !
!      cld_frac  (:,:) - layer total cloud fraction                     !
!      cld_lwp   (:,:) - layer cloud liq water path       (g/m**2)      !
!      cld_reliq (:,:) - mean eff radius for liq cloud    (micron)      !
!      cld_iwp   (:,:) - layer cloud ice water path       (g/m**2)      !
!      cld_reice (:,:) - mean eff radius for ice cloud    (micron)      !
!      cld_rwp   (:,:) - layer rain drop water path       not assigned  !
!      cld_rerain(:,:) - mean eff radius for rain drop    (micron)      !
!  *** cld_swp   (:,:) - layer snow flake water path      not assigned  !
!      cld_resnow(:,:) - mean eff radius for snow flake   (micron)      !
!                                                                       !
! module variables:                                                     !
!   ivflip          : control flag of vertical index direction          !
!                     =0: index from toa to surface                     !
!                     =1: index from surface to toa                     !
!   lcrick          : control flag for eliminating crick                !
!                     =t: apply layer smoothing to eliminate crick      !
!                     =f: do not apply layer smoothing                  !
!   lcnorm          : control flag for in-cld condensate                !
!                     =t: normalize cloud condensate                    !
!                     =f: not normalize cloud condensate                !
!                                                                       !
!  ====================    end of description    =====================  !
!
      implicit none

!  ---  inputs
      integer,  intent(in) :: ix, nlay, nlp1,kdt

      real (kind=kind_phys), dimension(:,:), intent(in) :: plvl, plyr,    &
     &       tlyr, tvly, qlyr, qstl, rhly, clw, dz, delp, dzlay
!     &       tlyr, tvly, qlyr, qstl, rhly, clw, cnvw, cnvc
!      real (kind=kind_phys), dimension(:,:), intent(in) :: deltaq
      real (kind=kind_phys), dimension(:,:) :: deltaq, cnvw, cnvc
      real (kind=kind_phys) qtmp,qsc,rhs
      real (kind=kind_phys), intent(in) :: sup
      real (kind=kind_phys), parameter :: epsq = 1.0e-12

      real (kind=kind_phys), dimension(:),   intent(in) :: xlat, xlon,    &
     &       slmsk
      integer :: me

!  --- inputs/outputs

      real (kind=kind_phys), dimension(:,:), intent(inout) ::            &
     &   cld_frac, cld_lwp, cld_reliq, cld_iwp, cld_reice,               &
     &   cld_rwp, cld_rerain, cld_swp, cld_resnow

!  ---  local variables:
      real (kind=kind_phys), dimension(ix,nlay) :: cldtot, cldcnv,      &
     &       cwp, cip, crp, csp, rew, rei, res, rer, tem2d, clwf

      real (kind=kind_phys) :: clwmin, clwm, clwt, onemrh, value,       &
     &       tem1, tem2, tem3

      integer :: i, k, id, nf

!
!===> ... begin here
!
      do k = 1, nlay
        do i = 1, ix
          cldtot(i,k) = 0.0
          cldcnv(i,k) = 0.0
          cwp   (i,k) = 0.0
          cip   (i,k) = 0.0
          crp   (i,k) = 0.0
          csp   (i,k) = 0.0
          rew   (i,k) = reliq_def            ! default liq radius to 10 micron
          rei   (i,k) = reice_def            ! default ice radius to 50 micron
          rer   (i,k) = rrain_def            ! default rain radius to 1000 micron
          res   (i,k) = rsnow_def            ! default snow radius to 250 micron
          tem2d (i,k) = min( 1.0, max( 0.0, (con_ttp-tlyr(i,k))*0.05 ) )
          clwf(i,k)   = 0.0
        enddo
      enddo
!
      if ( lcrick ) then
        do i = 1, ix
          clwf(i,1)    = 0.75*clw(i,1)    + 0.25*clw(i,2)
          clwf(i,nlay) = 0.75*clw(i,nlay) + 0.25*clw(i,nlay-1)
        enddo
        do k = 2, nlay-1
          do i = 1, ix
            clwf(i,k) = 0.25*clw(i,k-1) + 0.5*clw(i,k) + 0.25*clw(i,k+1)
          enddo
        enddo
      else
        do k = 1, nlay
          do i = 1, ix
            clwf(i,k) = clw(i,k)
          enddo
        enddo
      endif

      if(kdt==1) then
        do k = 1, nlay
          do i = 1, ix
            deltaq(i,k) = (1.-0.95)*qstl(i,k)
          enddo
        enddo
      endif

!> -# Calculate liquid/ice condensate path in \f$ g/m^2 \f$

        do k = 1, nlay
          do i = 1, ix
            clwt = max(0.0,(clwf(i,k)+cnvw(i,k))) * gfac * delp(i,k)
            cip(i,k) = clwt * tem2d(i,k)
            cwp(i,k) = clwt - cip(i,k)
          enddo
        enddo

!> -# Calculate effective liquid cloud droplet radius over land.

      do i = 1, ix
        if (nint(slmsk(i)) == 1) then
          do k = 1, nlay
            rew(i,k) = 5.0 + 5.0 * tem2d(i,k)
          enddo
        endif
      enddo

!> -# Calculate layer cloud fraction.

          do k = 1, nlay
          do i = 1, ix
            tem1 = tlyr(i,k) - 273.16
            if(tem1 < con_thgni) then  ! for pure ice, has to be consistent with gscond
              qsc = sup * qstl(i,k)
              rhs = sup
            else
              qsc = qstl(i,k)
              rhs = 1.0
            endif
           if(rhly(i,k) >= rhs) then
             cldtot(i,k) = 1.0
           else
             qtmp = qlyr(i,k) + clwf(i,k) - qsc
             if(deltaq(i,k) > epsq) then
!              if(qtmp <= -deltaq(i,k) .or. cwmik < epsq) then
               if(qtmp <= -deltaq(i,k)) then
                 cldtot(i,k) = 0.0
               elseif(qtmp >= deltaq(i,k)) then
                 cldtot(i,k) = 1.0
               else
                 cldtot(i,k) = 0.5*qtmp/deltaq(i,k) + 0.5
                 cldtot(i,k) = max(cldtot(i,k),0.0)
                 cldtot(i,k) = min(cldtot(i,k),1.0)
               endif
             else
               if(qtmp > 0.) then
                 cldtot(i,k) = 1.0
               else
                 cldtot(i,k) = 0.0
               endif
             endif
           endif
           cldtot(i,k) = cnvc(i,k) + (1-cnvc(i,k))*cldtot(i,k)
           cldtot(i,k) = max(cldtot(i,k),0.)
           cldtot(i,k) = min(cldtot(i,k),1.)

          enddo
          enddo

      do k = 1, nlay
        do i = 1, ix
          if (cldtot(i,k) < climit) then
            cldtot(i,k) = 0.0
            cwp(i,k)    = 0.0
            cip(i,k)    = 0.0
            crp(i,k)    = 0.0
            csp(i,k)    = 0.0
          endif
        enddo
      enddo

      if ( lcnorm ) then
        do k = 1, nlay
          do i = 1, ix
            if (cldtot(i,k) >= climit) then
              tem1 = 1.0 / max(climit2, cldtot(i,k))
              cwp(i,k) = cwp(i,k) * tem1
              cip(i,k) = cip(i,k) * tem1
              crp(i,k) = crp(i,k) * tem1
              csp(i,k) = csp(i,k) * tem1
            endif
          enddo
        enddo
      endif

!> -# Calculate effective ice cloud droplet radius following Heymsfield
!!    and McFarquhar (1996) \cite heymsfield_and_mcfarquhar_1996.

      do k = 1, nlay
        do i = 1, ix
          tem2 = tlyr(i,k) - con_ttp

          if (cip(i,k) > 0.0) then
!           tem3 = gord * cip(i,k) * (plyr(i,k)/delp(i,k)) / tvly(i,k)
            tem3 = gord * cip(i,k) * plyr(i,k) / (delp(i,k)*tvly(i,k))

            if (tem2 < -50.0) then
              rei(i,k) = (1250.0/9.917) * tem3 ** 0.109
            elseif (tem2 < -40.0) then
              rei(i,k) = (1250.0/9.337) * tem3 ** 0.08
            elseif (tem2 < -30.0) then
              rei(i,k) = (1250.0/9.208) * tem3 ** 0.055
            else
              rei(i,k) = (1250.0/9.387) * tem3 ** 0.031
            endif
!           rei(i,k)   = max(20.0, min(rei(i,k), 300.0))
!           rei(i,k)   = max(10.0, min(rei(i,k), 100.0))
            rei(i,k)   = max(10.0, min(rei(i,k), 150.0))
!           rei(i,k)   = max(5.0, min(rei(i,k), 130.0))
          endif
        enddo
      enddo

!
      do k = 1, NLAY
        do i = 1, IX
          cld_frac(i,k)   = cldtot(i,k)
          cld_lwp(i,k)    = cwp(i,k)
          cld_reliq(i,k)  = rew(i,k)
          cld_iwp(i,k)    = cip(i,k)
          cld_reice(i,k)  = rei(i,k)
!         cld_rwp(i,k)    = 0.0
          cld_rerain(i,k) = rer(i,k)
!         cld_swp(i,k)    = 0.0
          cld_resnow(i,k) = res(i,k)
        enddo
      enddo
!
      return
!...................................
      end subroutine progcld_zhao_carr_pdf
!! @}
!-----------------------------------


!-----------------------------------
!> \ingroup module_radiation_clouds
!> This subroutine computes cloud related quantities using
!! GFDL Lin MP prognostic cloud microphysics scheme.
!>\section progcld_gfdl_lin General Algorithm
!! @{
      subroutine progcld_gfdl_lin                                       &
     &     ( plyr,plvl,tlyr,tvly,qlyr,qstl,rhly,clw,cnvw,cnvc,          & !  ---  inputs:
     &       xlat,xlon,slmsk,cldtot, dz, delp,                          &
     &       IX, NLAY, NLP1,                                            &
     &       dzlay, cldtot1, cldcnv,                                    &
     &       cld_frac, cld_lwp, cld_reliq, cld_iwp,                     & !  ---  outputs
     &       cld_reice,cld_rwp, cld_rerain,cld_swp, cld_resnow          &
     &      )

! =================   subprogram documentation block   ================ !
!                                                                       !
! subprogram:    progcld_gfdl_lin    computes cloud related quantities using    !
!   GFDL Lin MP prognostic cloud microphysics scheme.                   !
!                                                                       !
! abstract:  this program computes cloud fractions from cloud           !
!   condensates, calculates liquid/ice cloud droplet effective radius,  !
!   and computes the low, mid, high, total and boundary layer cloud     !
!   fractions and the vertical indices of low, mid, and high cloud      !
!   top and base.  the three vertical cloud domains are set up in the   !
!   initial subroutine "cld_init".                                      !
!                                                                       !
! usage:         call progcld_gfdl_lin                                          !
!                                                                       !
! subprograms called:   gethml                                          !
!                                                                       !
! attributes:                                                           !
!   language:   fortran 90                                              !
!   machine:    ibm-sp, sgi                                             !
!                                                                       !
!                                                                       !
!  ====================  definition of variables  ====================  !
!                                                                       !
! input variables:                                                      !
!   plyr  (IX,NLAY) : model layer mean pressure in mb (100Pa)           !
!   plvl  (IX,NLP1) : model level pressure in mb (100Pa)                !
!   tlyr  (IX,NLAY) : model layer mean temperature in k                 !
!   tvly  (IX,NLAY) : model layer virtual temperature in k              !
!   qlyr  (IX,NLAY) : layer specific humidity in gm/gm                  !
!   qstl  (IX,NLAY) : layer saturate humidity in gm/gm                  !
!   rhly  (IX,NLAY) : layer relative humidity (=qlyr/qstl)              !
!   clw   (IX,NLAY) : layer cloud condensate amount                     !
!   cnvw  (IX,NLAY) : layer convective cloud condensate                 !
!   cnvc  (IX,NLAY) : layer convective cloud cover                      !
!   xlat  (IX)      : grid latitude in radians, default to pi/2 -> -pi/2!
!                     range, otherwise see in-line comment              !
!   xlon  (IX)      : grid longitude in radians  (not used)             !
!   slmsk (IX)      : sea/land mask array (sea:0,land:1,sea-ice:2)      !
!   dz    (ix,nlay) : layer thickness (km)                              !
!   delp  (ix,nlay) : model layer pressure thickness in mb (100Pa)      !
!   IX              : horizontal dimention                              !
!   NLAY,NLP1       : vertical layer/level dimensions                   !
!   dzlay(ix,nlay)  : thickness between model layer centers (km)        !
!                                                                       !
! output variables:                                                     !
!   cloud profiles:                                                     !
!      cld_frac  (:,:) - layer total cloud fraction                     !
!      cld_lwp   (:,:) - layer cloud liq water path       (g/m**2)      !
!      cld_reliq (:,:) - mean eff radius for liq cloud    (micron)      !
!      cld_iwp   (:,:) - layer cloud ice water path       (g/m**2)      !
!      cld_reice (:,:) - mean eff radius for ice cloud    (micron)      !
!      cld_rwp   (:,:) - layer rain drop water path       not assigned  !
!      cld_rerain(:,:) - mean eff radius for rain drop    (micron)      !
!  *** cld_swp   (:,:) - layer snow flake water path      not assigned  !
!      cld_resnow(:,:) - mean eff radius for snow flake   (micron)      !
!                                                                       !
! module variables:                                                     !
!   ivflip          : control flag of vertical index direction          !
!                     =0: index from toa to surface                     !
!                     =1: index from surface to toa                     !
!   lsashal         : control flag for shallow convection               !
!   lcrick          : control flag for eliminating CRICK                !
!                     =t: apply layer smoothing to eliminate CRICK      !
!                     =f: do not apply layer smoothing                  !
!   lcnorm          : control flag for in-cld condensate                !
!                     =t: normalize cloud condensate                    !
!                     =f: not normalize cloud condensate                !
!                                                                       !
!  ====================    end of description    =====================  !
!
      implicit none

!  ---  inputs
      integer,  intent(in) :: IX, NLAY, NLP1

      real (kind=kind_phys), dimension(:,:), intent(in) :: plvl, plyr,  &
     &       tlyr, tvly, qlyr, qstl, rhly, clw, cldtot, cnvw, cnvc,     &
     &       delp, dz, dzlay

      real (kind=kind_phys), dimension(:),   intent(in) :: xlat, xlon,  &
     &       slmsk

      real (kind=kind_phys), dimension(:,:), intent(inout) :: cldtot1

!  --- inputs/outputs

      real (kind=kind_phys), dimension(:,:), intent(inout) ::            &
     &   cld_frac, cld_lwp, cld_reliq, cld_iwp, cld_reice,               &
     &   cld_rwp, cld_rerain, cld_swp, cld_resnow

!  ---  local variables:
      real (kind=kind_phys), dimension(IX,NLAY) :: cldcnv,              &
     &       cwp, cip, crp, csp, rew, rei, res, rer, tem2d, clwf

      real (kind=kind_phys) :: clwmin, clwm, clwt, onemrh, value,       &
     &       tem1, tem2, tem3

      integer :: i, k, id, nf

!
!===> ... begin here
!
!> - Assign liquid/ice/rain/snow cloud doplet effective radius as default value.
      do k = 1, NLAY
        do i = 1, IX
          cldcnv(i,k) = 0.0
          cwp   (i,k) = 0.0
          cip   (i,k) = 0.0
          crp   (i,k) = 0.0
          csp   (i,k) = 0.0
          rew   (i,k) = reliq_def            !< default liq radius to 10 micron
          rei   (i,k) = reice_def            !< default ice radius to 50 micron
          rer   (i,k) = rrain_def            !< default rain radius to 1000 micron
          res   (i,k) = rsnow_def            !< default snow radius to 250 micron
          tem2d (i,k) = min( 1.0, max( 0.0, (con_ttp-tlyr(i,k))*0.05 ) )
          clwf(i,k)   = 0.0
        enddo
      enddo
!
      if ( lcrick ) then
        do i = 1, IX
          clwf(i,1)    = 0.75*clw(i,1)    + 0.25*clw(i,2)
          clwf(i,nlay) = 0.75*clw(i,nlay) + 0.25*clw(i,nlay-1)
        enddo
        do k = 2, NLAY-1
          do i = 1, IX
            clwf(i,K) = 0.25*clw(i,k-1) + 0.5*clw(i,k) + 0.25*clw(i,k+1)
          enddo
        enddo
      else
        do k = 1, NLAY
          do i = 1, IX
            clwf(i,k) = clw(i,k)
          enddo
        enddo
      endif

!> - Compute liquid/ice condensate path in \f$g m^{-2}\f$.

        do k = 1, NLAY
          do i = 1, IX
            clwt     = max(0.0,(clwf(i,k)+cnvw(i,k))) * gfac * delp(i,k)
            cip(i,k) = clwt * tem2d(i,k)
            cwp(i,k) = clwt - cip(i,k)
          enddo
        enddo

!> - Compute effective liquid cloud droplet radius over land.

      do i = 1, IX
        if (nint(slmsk(i)) == 1) then
          do k = 1, NLAY
            rew(i,k) = 5.0 + 5.0 * tem2d(i,k)
          enddo
        endif
      enddo

      do k = 1, NLAY
        do i = 1, IX
          if (cldtot(i,k) < climit) then
            cwp(i,k)    = 0.0
            cip(i,k)    = 0.0
            crp(i,k)    = 0.0
            csp(i,k)    = 0.0
          endif
        enddo
      enddo

      if ( lcnorm ) then
        do k = 1, NLAY
          do i = 1, IX
            if (cldtot(i,k) >= climit) then
              tem1 = 1.0 / max(climit2, cldtot(i,k))
              cwp(i,k) = cwp(i,k) * tem1
              cip(i,k) = cip(i,k) * tem1
              crp(i,k) = crp(i,k) * tem1
              csp(i,k) = csp(i,k) * tem1
            endif
          enddo
        enddo
      endif

!> - Compute effective ice cloud droplet radius in Heymsfield and McFarquhar (1996)
!! \cite heymsfield_and_mcfarquhar_1996 .

      do k = 1, NLAY
        do i = 1, IX
          tem2 = tlyr(i,k) - con_ttp

          if (cip(i,k) > 0.0) then
            tem3 = gord * cip(i,k) * plyr(i,k) / (delp(i,k)*tvly(i,k))

            if (tem2 < -50.0) then
              rei(i,k) = (1250.0/9.917) * tem3 ** 0.109
            elseif (tem2 < -40.0) then
              rei(i,k) = (1250.0/9.337) * tem3 ** 0.08
            elseif (tem2 < -30.0) then
              rei(i,k) = (1250.0/9.208) * tem3 ** 0.055
            else
              rei(i,k) = (1250.0/9.387) * tem3 ** 0.031
            endif
!           rei(i,k)   = max(20.0, min(rei(i,k), 300.0))
!           rei(i,k)   = max(10.0, min(rei(i,k), 100.0))
            rei(i,k)   = max(10.0, min(rei(i,k), 150.0))
!           rei(i,k)   = max(5.0,  min(rei(i,k), 130.0))
          endif
        enddo
      enddo

      do k = 1, NLAY
        do i = 1, IX
          cldtot1(i,k) = cldtot(i,k)
        enddo
      enddo

!
      do k = 1, NLAY
        do i = 1, IX
          cld_frac(i,k)   = cldtot(i,k)
          cld_lwp(i,k)    = cwp(i,k)
          cld_reliq(i,k)  = rew(i,k)
          cld_iwp(i,k)    = cip(i,k)
          cld_reice(i,k)  = rei(i,k)
!         cld_rwp(i,k)    = 0.0
          cld_rerain(i,k) = rer(i,k)
!         cld_swp(i,k)    = 0.0
          cld_resnow(i,k) = res(i,k)
        enddo
      enddo
!
      return
!...................................
      end subroutine progcld_gfdl_lin
!! @}
!-----------------------------------

!-----------------------------------
!> \ingroup module_radiation_clouds
!! This subroutine computes cloud related quantities using
!! Ferrier-Aligo cloud microphysics scheme.
      subroutine progcld_fer_hires                                      &
     &     ( plyr,plvl,tlyr,tvly,qlyr,qstl,rhly,clw,                    &    !  ---  inputs:
     &       xlat,xlon,slmsk,dz,delp,                                   &
     &       ntrac,ntcw,ntiw,ntrw,                                      &
     &       IX, NLAY, NLP1, icloud,                                    &
     &       uni_cld, lmfshal, lmfdeep2, cldcov,                        &
     &       re_cloud,re_ice,re_snow,                                   &
     &       dzlay, cldtot, cldcnv,                                     &
     &       cld_frac, cld_lwp, cld_reliq, cld_iwp,                     & !  ---  outputs
     &       cld_reice,cld_rwp, cld_rerain,cld_swp, cld_resnow          &
     &      )

! =================   subprogram documentation block   ================ !
!                                                                       !
! subprogram:    progcld_fer_hires    computes cloud related quantities using    !
!   Ferrier-Aligo cloud microphysics scheme.                            !
!                                                                       !
! abstract:  this program computes cloud fractions from cloud           !
!   condensates,                                                        !
!   and computes the low, mid, high, total and boundary layer cloud     !
!   fractions and the vertical indices of low, mid, and high cloud      !
!   top and base.  the three vertical cloud domains are set up in the   !
!   initial subroutine "cld_init".                                      !
!                                                                       !
! usage:         call progcld_fer_hires                                          !
!                                                                       !
! subprograms called:   gethml                                          !
!                                                                       !
! attributes:                                                           !
!   language:   fortran 90                                              !
!   machine:    ibm-sp, sgi                                             !
!                                                                       !
!                                                                       !
!  ====================  definition of variables  ====================  !
!                                                                       !
! input variables:                                                      !
!   plyr  (IX,NLAY) : model layer mean pressure in mb (100Pa)           !
!   plvl  (IX,NLP1) : model level pressure in mb (100Pa)                !
!   tlyr  (IX,NLAY) : model layer mean temperature in k                 !
!   tvly  (IX,NLAY) : model layer virtual temperature in k              !
!   qlyr  (IX,NLAY) : layer specific humidity in gm/gm                  !
!   qstl  (IX,NLAY) : layer saturate humidity in gm/gm                  !
!   rhly  (IX,NLAY) : layer relative humidity (=qlyr/qstl)              !
!   clw   (IX,NLAY,ntrac) : layer cloud condensate amount               !
!   xlat  (IX)      : grid latitude in radians, default to pi/2 -> -pi/2!
!                     range, otherwise see in-line comment              !
!   xlon  (IX)      : grid longitude in radians  (not used)             !
!   slmsk (IX)      : sea/land mask array (sea:0,land:1,sea-ice:2)      !
!   dz    (ix,nlay) : layer thickness (km)                              !
!   delp  (ix,nlay) : model layer pressure thickness in mb (100Pa)      !
!   IX              : horizontal dimention                              !
!   NLAY,NLP1       : vertical layer/level dimensions                   !
!   icloud          : cloud effect to the optical depth in radiation    !
!   uni_cld         : logical - true for cloud fraction from shoc       !
!   lmfshal         : logical - true for mass flux shallow convection   !
!   lmfdeep2        : logical - true for mass flux deep convection      !
!   cldcov          : layer cloud fraction (used when uni_cld=.true.    !
!   dzlay(ix,nlay)  : thickness between model layer centers (km)        !
!                                                                       !
! output variables:                                                     !
!   cloud profiles:                                                     !
!      cld_frac  (:,:) - layer total cloud fraction                     !
!      cld_lwp   (:,:) - layer cloud liq water path       (g/m**2)      !
!      cld_reliq (:,:) - mean eff radius for liq cloud    (micron)      !
!      cld_iwp   (:,:) - layer cloud ice water path       (g/m**2)      !
!      cld_reice (:,:) - mean eff radius for ice cloud    (micron)      !
!      cld_rwp   (:,:) - layer rain drop water path       not assigned  !
!      cld_rerain(:,:) - mean eff radius for rain drop    (micron)      !
!  *** cld_swp   (:,:) - layer snow flake water path      not assigned  !
!      cld_resnow(:,:) - mean eff radius for snow flake   (micron)      !
!                                                                       !
! module variables:                                                     !
!   ivflip          : control flag of vertical index direction          !
!                     =0: index from toa to surface                     !
!                     =1: index from surface to toa                     !
!   lmfshal         : mass-flux shallow conv scheme flag                !
!   lmfdeep2        : scale-aware mass-flux deep conv scheme flag       !
!   lcrick          : control flag for eliminating CRICK                !
!                     =t: apply layer smoothing to eliminate CRICK      !
!                     =f: do not apply layer smoothing                  !
!   lcnorm          : control flag for in-cld condensate                !
!                     =t: normalize cloud condensate                    !
!                     =f: not normalize cloud condensate                !
!                                                                       !
!  ====================    end of description    =====================  !
!
      implicit none

!  ---  inputs
      integer,  intent(in) :: IX, NLAY, NLP1, ICLOUD
      integer,  intent(in) :: ntrac, ntcw, ntiw, ntrw

      logical, intent(in)  :: uni_cld, lmfshal, lmfdeep2

      real (kind=kind_phys), dimension(:,:), intent(in) :: plvl, plyr,  &
     &       tlyr, tvly, qlyr, qstl, rhly, cldcov, delp, dz, dzlay

      real (kind=kind_phys), dimension(:,:), intent(inout) ::           &
     &      re_cloud, re_ice, re_snow

      real (kind=kind_phys), dimension(:,:,:), intent(in) :: clw

      real (kind=kind_phys), dimension(:),   intent(in) :: xlat, xlon,  &
     &       slmsk

!  --- inputs/outputs

      real (kind=kind_phys), dimension(:,:), intent(inout) ::            &
     &   cld_frac, cld_lwp, cld_reliq, cld_iwp, cld_reice,               &
     &   cld_rwp, cld_rerain, cld_swp, cld_resnow

!  ---  local variables:
      real (kind=kind_phys), dimension(IX,NLAY) :: cldtot, cldcnv,      &
     &       cwp, cip, crp, csp, rew, rei, res, rer, tem2d, clwf

      real (kind=kind_phys) :: clwmin, clwm, clwt, onemrh, value,       &
     &       tem1, tem2, tem3

      integer :: i, k, id, nf

!  ---  constant values
!     real (kind=kind_phys), parameter :: xrc3 = 200.
      real (kind=kind_phys), parameter :: xrc3 = 100.

!
!===> ... begin here
!
      do k = 1, NLAY
        do i = 1, IX
          cldtot(i,k) = 0.0
          cldcnv(i,k) = 0.0
          cwp   (i,k) = 0.0
          cip   (i,k) = 0.0
          crp   (i,k) = 0.0
          csp   (i,k) = 0.0
          rew   (i,k) = re_cloud(i,k)
          rei   (i,k) = re_ice(i,k)
          rer   (i,k) = rrain_def            ! default rain radius to 1000 micron
          res   (i,k) = re_snow(i,K)
!         tem2d (i,k) = min( 1.0, max( 0.0, (con_ttp-tlyr(i,k))*0.05 ) )
          clwf(i,k)   = 0.0
        enddo
      enddo
!
!      if ( lcrick ) then
!        do i = 1, IX
!          clwf(i,1)    = 0.75*clw(i,1)    + 0.25*clw(i,2)
!          clwf(i,nlay) = 0.75*clw(i,nlay) + 0.25*clw(i,nlay-1)
!        enddo
!        do k = 2, NLAY-1
!          do i = 1, IX
!            clwf(i,K) = 0.25*clw(i,k-1) + 0.5*clw(i,k) + 0.25*clw(i,k+1)
!          enddo
!        enddo
!      else
!        do k = 1, NLAY
!          do i = 1, IX
!            clwf(i,k) = clw(i,k)
!          enddo
!        enddo
!      endif

        do k = 1, NLAY
          do i = 1, IX
            clwf(i,k) = clw(i,k,ntcw) +  clw(i,k,ntiw)
          enddo
        enddo

!> - Compute cloud liquid/ice condensate path in \f$ g/m^2 \f$ .

        do k = 1, NLAY
          do i = 1, IX
            cwp(i,k) = max(0.0, clw(i,k,ntcw) * gfac * delp(i,k))
            cip(i,k) = max(0.0, clw(i,k,ntiw) * gfac * delp(i,k))
            crp(i,k) = max(0.0, clw(i,k,ntrw) * gfac * delp(i,k))
            csp(i,k) = 0.0
          enddo
        enddo

!mz*      if (uni_cld) then     ! use unified sgs clouds generated outside
!mz*  use unified sgs clouds generated outside
      if (uni_cld) then
        do k = 1, NLAY
          do i = 1, IX
            cldtot(i,k) = cldcov(i,k)
          enddo
        enddo

      else

!> - Calculate layer cloud fraction.

        if (.not. lmfshal) then
          call cloud_fraction_XuRandall                                 &
     &      ( IX, NLAY, plyr, clwf, rhly, qstl,                         & !  ---  inputs
     &        cldtot )                                                  & !  ---  outputs
        else
          call cloud_fraction_mass_flx_1                                &
     &      ( IX, NLAY, lmfdeep2, xrc3, plyr, clwf, rhly, qstl,         & !  ---  inputs
     &        cldtot )
        endif

      endif                                ! if (uni_cld) then

      do k = 1, NLAY
        do i = 1, IX
          if (cldtot(i,k) < climit) then
            cldtot(i,k) = 0.0
            cwp(i,k)    = 0.0
            cip(i,k)    = 0.0
            crp(i,k)    = 0.0
            csp(i,k)    = 0.0
          endif
        enddo
      enddo

      if ( lcnorm ) then
        do k = 1, NLAY
          do i = 1, IX
            if (cldtot(i,k) >= climit) then
              tem1 = 1.0 / max(climit2, cldtot(i,k))
              cwp(i,k) = cwp(i,k) * tem1
              cip(i,k) = cip(i,k) * tem1
              crp(i,k) = crp(i,k) * tem1
              csp(i,k) = csp(i,k) * tem1
            endif
          enddo
        enddo
      endif
!
      do k = 1, NLAY
        do i = 1, IX
          cld_frac(i,k)   = cldtot(i,k)
          cld_lwp(i,k)    = cwp(i,k)
          cld_reliq(i,k)  = rew(i,k)
          cld_iwp(i,k)    = cip(i,k)
          cld_reice(i,k)  = rei(i,k)
          cld_rwp(i,k)    = crp(i,k)
          cld_rerain(i,k) = rer(i,k)
          cld_swp(i,k)    = 0.0
          cld_resnow(i,k) = 10.0
          re_cloud(i,k) = rew(i,k)
          re_ice(i,k)   = rei(i,k)
          re_snow(i,k)  = 10.
        enddo
      enddo
!
      return
!...................................
      end subroutine progcld_fer_hires
!...................................


! This subroutine is used by Thompson/WSM6/NSSL cloud microphysics (EMC)
      subroutine progcld_thompson_wsm6                                  &
     &     ( plyr,plvl,tlyr,qlyr,qstl,rhly,clw,                         &    !  ---  inputs:
     &       xlat,xlon,slmsk,dz,delp,                                   &
     &       ntrac,ntcw,ntiw,ntrw,ntsw,ntgl,                            &
     &       IX, NLAY, NLP1,                                            &
     &       uni_cld, lmfshal, lmfdeep2, cldcov, cnvw,                  &
     &       re_cloud,re_ice,re_snow,                                   &
     &       lwp_ex, iwp_ex, lwp_fc, iwp_fc,                            &
     &       dzlay, cldtot, cldcnv,                                     &
     &       cld_frac, cld_lwp, cld_reliq, cld_iwp,                     & !  ---  outputs
     &       cld_reice,cld_rwp, cld_rerain,cld_swp, cld_resnow          &
     &      )

! =================   subprogram documentation block   ================ !
!                                                                       !
! subprogram:    progcld_thompson_wsm6                                  !
!   computes cloud related quantities using                             !
!   Thompson/WSM6/NSSL cloud microphysics scheme.                       !
!                                                                       !
! abstract:  this program computes cloud fractions from cloud           !
!   condensates,                                                        !
!   and computes the low, mid, high, total and boundary layer cloud     !
!   fractions and the vertical indices of low, mid, and high cloud      !
!   top and base.  the three vertical cloud domains are set up in the   !
!   initial subroutine "cld_init".                                      !
!                                                                       !
! usage:         call progcld_thompson_wsm6                                          !
!                                                                       !
! subprograms called:   gethml                                          !
!                                                                       !
! attributes:                                                           !
!   language:   fortran 90                                              !
!   machine:    ibm-sp, sgi                                             !
!                                                                       !
!                                                                       !
!  ====================  definition of variables  ====================  !
!                                                                       !
!                                                                       !
! input variables:                                                      !
!   plyr  (IX,NLAY) : model layer mean pressure in mb (100Pa)           !
!   plvl  (IX,NLP1) : model level pressure in mb (100Pa)                !
!   tlyr  (IX,NLAY) : model layer mean temperature in k                 !
!   tvly  (IX,NLAY) : model layer virtual temperature in k              !
!   qlyr  (IX,NLAY) : layer specific humidity in gm/gm                  !
!   qstl  (IX,NLAY) : layer saturate humidity in gm/gm                  !
!   rhly  (IX,NLAY) : layer relative humidity (=qlyr/qstl)              !
!   clw   (IX,NLAY,ntrac) : layer cloud condensate amount               !
!   xlat  (IX)      : grid latitude in radians, default to pi/2 -> -pi/2!
!                     range, otherwise see in-line comment              !
!   xlon  (IX)      : grid longitude in radians  (not used)             !
!   slmsk (IX)      : sea/land mask array (sea:0,land:1,sea-ice:2)      !
!   dz    (ix,nlay) : layer thickness (km)                              !
!   delp  (ix,nlay) : model layer pressure thickness in mb (100Pa)      !
!   IX              : horizontal dimention                              !
!   NLAY,NLP1       : vertical layer/level dimensions                   !
!   uni_cld         : logical - true for cloud fraction from shoc       !
!   lmfshal         : logical - true for mass flux shallow convection   !
!   lmfdeep2        : logical - true for mass flux deep convection      !
!   cldcov          : layer cloud fraction (used when uni_cld=.true.    !
!                                                                       !
! output variables:                                                     !
!   cloud profiles:                                                     !
!      cld_frac  (:,:) - layer total cloud fraction                     !
!      cld_lwp   (:,:) - layer cloud liq water path       (g/m**2)      !
!      cld_reliq (:,:) - mean eff radius for liq cloud    (micron)      !
!      cld_iwp   (:,:) - layer cloud ice water path       (g/m**2)      !
!      cld_reice (:,:) - mean eff radius for ice cloud    (micron)      !
!      cld_rwp   (:,:) - layer rain drop water path       not assigned  !
!      cld_rerain(:,:) - mean eff radius for rain drop    (micron)      !
!  *** cld_swp   (:,:) - layer snow flake water path      not assigned  !
!      cld_resnow(:,:) - mean eff radius for snow flake   (micron)      !
!  *** fu's scheme need to be normalized by snow density (g/m**3/1.0e6) !
!   clds  (IX,5)    : fraction of clouds for low, mid, hi, tot, bl      !
!   mtop  (IX,3)    : vertical indices for low, mid, hi cloud tops      !
!   mbot  (IX,3)    : vertical indices for low, mid, hi cloud bases     !
!   de_lgth(ix)     : clouds decorrelation length (km)                  !
!                                                                       !
! module variables:                                                     !
!   ivflip          : control flag of vertical index direction          !
!                     =0: index from toa to surface                     !
!                     =1: index from surface to toa                     !
!   lmfshal         : mass-flux shallow conv scheme flag                !
!   lmfdeep2        : scale-aware mass-flux deep conv scheme flag       !
!   lcrick          : control flag for eliminating CRICK                !
!                     =t: apply layer smoothing to eliminate CRICK      !
!                     =f: do not apply layer smoothing                  !
!   lcnorm          : control flag for in-cld condensate                !
!                     =t: normalize cloud condensate                    !
!                     =f: not normalize cloud condensate                !
!                                                                       !
!  ====================    end of description    =====================  !
!
      implicit none

!  ---  inputs
      integer,  intent(in) :: IX, NLAY, NLP1
      integer,  intent(in) :: ntrac, ntcw, ntiw, ntrw, ntsw, ntgl

      logical, intent(in)  :: uni_cld, lmfshal, lmfdeep2

      real (kind=kind_phys), dimension(:,:), intent(in) :: plvl, plyr,  &
     &       tlyr, qlyr, qstl, rhly, cldcov, delp, dz, dzlay,           &
     &       re_cloud, re_ice, re_snow, cnvw
      real (kind=kind_phys), dimension(:), intent(inout) ::             &
     &       lwp_ex, iwp_ex, lwp_fc, iwp_fc

      real (kind=kind_phys), dimension(:,:,:), intent(in) :: clw

      real (kind=kind_phys), dimension(:),   intent(in) :: xlat, xlon,  &
     &       slmsk

!  --- inputs/outputs

      real (kind=kind_phys), dimension(:,:), intent(inout) ::            &
     &   cld_frac, cld_lwp, cld_reliq, cld_iwp, cld_reice,               &
     &   cld_rwp, cld_rerain, cld_swp, cld_resnow

!  ---  local variables:
      real (kind=kind_phys), dimension(IX,NLAY) :: cldtot, cldcnv,      &
     &       cwp, cip, crp, csp, rew, rei, res, rer, tem2d, clwf

      real (kind=kind_phys) :: clwmin, clwm, clwt, onemrh, value,       &
     &       tem1, tem2, tem3

      integer :: i, k, id, nf

!  ---  constant values
      real (kind=kind_phys), parameter :: xrc3 = 200.

!
!===> ... begin here

      do k = 1, NLAY
        do i = 1, IX
          cldtot(i,k) = 0.0
          cldcnv(i,k) = 0.0
          cwp   (i,k) = 0.0
          cip   (i,k) = 0.0
          crp   (i,k) = 0.0
          csp   (i,k) = 0.0
          rew   (i,k) = re_cloud(i,k)
          rei   (i,k) = re_ice(i,k)
          rer   (i,k) = rrain_def            ! default rain radius to 1000 micron
          res   (i,k) = re_snow(i,K)
!         tem2d (i,k) = min( 1.0, max( 0.0, (con_ttp-tlyr(i,k))*0.05 ) )
          clwf(i,k)   = 0.0
        enddo
      enddo
!
!
!      if ( lcrick ) then
!        do i = 1, IX
!          clwf(i,1)    = 0.75*clw(i,1)    + 0.25*clw(i,2)
!          clwf(i,nlay) = 0.75*clw(i,nlay) + 0.25*clw(i,nlay-1)
!        enddo
!        do k = 2, NLAY-1
!          do i = 1, IX
!            clwf(i,K) = 0.25*clw(i,k-1) + 0.5*clw(i,k) + 0.25*clw(i,k+1)
!          enddo
!        enddo
!      else
!        do k = 1, NLAY
!          do i = 1, IX
!            clwf(i,k) = clw(i,k)
!          enddo
!        enddo
!      endif

        do k = 1, NLAY
          do i = 1, IX
            clwf(i,k) = clw(i,k,ntcw) +  clw(i,k,ntiw) + clw(i,k,ntsw)
     &      + clw(i,k,ntrw) + cnvw(i,k)
          enddo
        enddo

!> - Compute cloud liquid/ice condensate path in \f$ g/m^2 \f$ .

        do k = 1, NLAY-1
          do i = 1, IX
            cwp(i,k) = max(0.0, clw(i,k,ntcw) * gfac * delp(i,k))
            cip(i,k) = max(0.0, clw(i,k,ntiw) * gfac * delp(i,k))
            crp(i,k) = max(0.0, clw(i,k,ntrw) * gfac * delp(i,k))
            csp(i,k) = max(0.0, clw(i,k,ntsw) * gfac * delp(i,k))
          enddo
        enddo

!> - Sum the liquid water and ice paths that come from explicit micro

      do i = 1, IX
         lwp_ex(i) = 0.0
         iwp_ex(i) = 0.0
         lwp_fc(i) = 0.0
         iwp_fc(i) = 0.0
         do k = 1, NLAY-1
            lwp_ex(i) = lwp_ex(i) + cwp(i,k)
            iwp_ex(i) = iwp_ex(i) + cip(i,k) + csp(i,k)
         enddo
         lwp_ex(i) = lwp_ex(i)*1.E-3
         iwp_ex(i) = iwp_ex(i)*1.E-3
      enddo

      if (uni_cld) then     ! use unified sgs clouds generated outside
        do k = 1, NLAY
          do i = 1, IX
            cldtot(i,k) = cldcov(i,k)
          enddo
        enddo

      else

!> - Calculate layer cloud fraction.

        if (.not. lmfshal) then
          call cloud_fraction_XuRandall                                 &
     &      ( IX, NLAY, plyr, clwf, rhly, qstl,                         & !  ---  inputs
     &        cldtot )                                                  & !  ---  outputs
        else
          call cloud_fraction_mass_flx_2                                &
     &      ( IX, NLAY, lmfdeep2, xrc3, plyr, clwf, rhly, qstl,         & !  ---  inputs
     &        cldtot )
        endif

      endif                                ! if (uni_cld) then

      do k = 1, NLAY
        do i = 1, IX
          if (cldtot(i,k) < climit) then
            cldtot(i,k) = 0.0
            cwp(i,k)    = 0.0
            cip(i,k)    = 0.0
            crp(i,k)    = 0.0
            csp(i,k)    = 0.0
          endif
        enddo
      enddo

      ! What portion of water and ice contents is associated with the
      ! partly cloudy boxes
      do i = 1, IX
         do k = 1, NLAY-1
            if (cldtot(i,k).ge.climit .and. cldtot(i,k).lt.ovcst) then
               lwp_fc(i) = lwp_fc(i) + cwp(i,k)
               iwp_fc(i) = iwp_fc(i) + cip(i,k) + csp(i,k)
            endif
         enddo
         lwp_fc(i) = lwp_fc(i)*1.E-3
         iwp_fc(i) = iwp_fc(i)*1.E-3
      enddo

      if ( lcnorm ) then
        do k = 1, NLAY
          do i = 1, IX
            if (cldtot(i,k) >= climit) then
              tem1 = 1.0 / max(climit2, cldtot(i,k))
              cwp(i,k) = cwp(i,k) * tem1
              cip(i,k) = cip(i,k) * tem1
              crp(i,k) = crp(i,k) * tem1
              csp(i,k) = csp(i,k) * tem1
            endif
          enddo
        enddo
      endif

      do k = 1, NLAY
        do i = 1, IX
          cld_frac(i,k)   = cldtot(i,k)
          cld_lwp(i,k)    = cwp(i,k)
          cld_reliq(i,k)  = rew(i,k)
          cld_iwp(i,k)    = cip(i,k)
          cld_reice(i,k)  = rei(i,k)
          cld_rwp(i,k)    = crp(i,k)  ! added for Thompson
          cld_rerain(i,k) = rer(i,k)
          cld_swp(i,k)    = csp(i,k)  ! added for Thompson
          cld_resnow(i,k) = res(i,k)
        enddo
      enddo

      return

!............................................
      end subroutine progcld_thompson_wsm6
!............................................
!mz



! This subroutine added by G. Thompson specifically to account for
! explicit (microphysics-produced) cloud liquid water, cloud ice, and
! snow with 100% cloud fraction.  Also, a parameterization for cloud
! fraction less than 1.0 but greater than 0.0 follows Mocko and Cotton
! (1996) from Sundqvist et al. (1989) with cloud fraction increasing
! as RH increases above a critical value.  In locations with non-zero
! (but less than 1.0) cloud fraction, there MUST be a value assigned
! to cloud liquid water and ice or else there is zero impact in the
! RRTMG radiation scheme.
      subroutine progcld_thompson                                       &
     &     ( plyr,plvl,tlyr,qlyr,qstl,rhly,clw,                         &    !  ---  inputs:
     &       xlat,xlon,slmsk,dz,delp,                                   &
     &       ntrac,ntcw,ntiw,ntrw,ntsw,ntgl,                            &
     &       IX, NLAY, NLP1,                                            &
     &       uni_cld, lmfshal, lmfdeep2, cldcov,                        &
     &       re_cloud,re_ice,re_snow,                                   &
     &       lwp_ex, iwp_ex, lwp_fc, iwp_fc,                            &
     &       dzlay,  gridkm, cldtot, cldcnv,                            &
     &       cld_frac, cld_lwp, cld_reliq, cld_iwp,                     & !  ---  outputs
     &       cld_reice,cld_rwp, cld_rerain,cld_swp, cld_resnow          &
     &      )

! =================   subprogram documentation block   ================ !
!                                                                       !
! subprogram:    progcld_thompson    computes cloud related quantities  !
!   using Thompson cloud microphysics scheme.                           !
!                                                                       !
! abstract:  this program computes cloud fractions from cloud           !
!   condensates,                                                        !
!   and computes the low, mid, high, total and boundary layer cloud     !
!   fractions and the vertical indices of low, mid, and high cloud      !
!   top and base.  the three vertical cloud domains are set up in the   !
!   initial subroutine "cld_init".                                      !
!                                                                       !
! usage:         call progcld_thompson                                  !
!                                                                       !
! subprograms called:   gethml                                          !
!                                                                       !
! attributes:                                                           !
!   language:   fortran 90                                              !
!   machine:    ibm-sp, sgi                                             !
!                                                                       !
!                                                                       !
!  ====================  definition of variables  ====================  !
!                                                                       !
!                                                                       !
! input variables:                                                      !
!   plyr  (IX,NLAY) : model layer mean pressure in mb (100Pa)           !
!   plvl  (IX,NLP1) : model level pressure in mb (100Pa)                !
!   tlyr  (IX,NLAY) : model layer mean temperature in k                 !
!   tvly  (IX,NLAY) : model layer virtual temperature in k              !
!   qlyr  (IX,NLAY) : layer specific humidity in gm/gm                  !
!   qstl  (IX,NLAY) : layer saturate humidity in gm/gm                  !
!   rhly  (IX,NLAY) : layer relative humidity (=qlyr/qstl)              !
!   clw   (IX,NLAY,ntrac) : layer cloud condensate amount               !
!   xlat  (IX)      : grid latitude in radians, default to pi/2 -> -pi/2!
!                     range, otherwise see in-line comment              !
!   xlon  (IX)      : grid longitude in radians  (not used)             !
!   slmsk (IX)      : sea/land mask array (sea:0,land:1,sea-ice:2)      !
!   dz    (ix,nlay) : layer thickness (km)                              !
!   delp  (ix,nlay) : model layer pressure thickness in mb (100Pa)      !
!   gridkm (IX)     : grid length in km                                 !
!   IX              : horizontal dimention                              !
!   NLAY,NLP1       : vertical layer/level dimensions                   !
!   uni_cld         : logical - true for cloud fraction from shoc       !
!   lmfshal         : logical - true for mass flux shallow convection   !
!   lmfdeep2        : logical - true for mass flux deep convection      !
!   cldcov          : layer cloud fraction (used when uni_cld=.true.    !
!                                                                       !
! output variables:                                                     !
!   cloud profiles:                                                     !
!      cld_frac  (:,:) - layer total cloud fraction                     !
!      cld_lwp   (:,:) - layer cloud liq water path       (g/m**2)      !
!      cld_reliq (:,:) - mean eff radius for liq cloud    (micron)      !
!      cld_iwp   (:,:) - layer cloud ice water path       (g/m**2)      !
!      cld_reice (:,:) - mean eff radius for ice cloud    (micron)      !
!      cld_rwp   (:,:) - layer rain drop water path       not assigned  !
!      cld_rerain(:,:) - mean eff radius for rain drop    (micron)      !
!  *** cld_swp   (:,:) - layer snow flake water path      not assigned  !
!      cld_resnow(:,:) - mean eff radius for snow flake   (micron)      !
!                                                                       !
! module variables:                                                     !
!   ivflip          : control flag of vertical index direction          !
!                     =0: index from toa to surface                     !
!                     =1: index from surface to toa                     !
!   lmfshal         : mass-flux shallow conv scheme flag                !
!   lmfdeep2        : scale-aware mass-flux deep conv scheme flag       !
!   lcrick          : control flag for eliminating CRICK                !
!                     =t: apply layer smoothing to eliminate CRICK      !
!                     =f: do not apply layer smoothing                  !
!   lcnorm          : control flag for in-cld condensate                !
!                     =t: normalize cloud condensate                    !
!                     =f: not normalize cloud condensate                !
!                                                                       !
!  ====================    end of description    =====================  !
!
      implicit none

!  ---  inputs
      integer,  intent(in) :: IX, NLAY, NLP1
      integer,  intent(in) :: ntrac, ntcw, ntiw, ntrw, ntsw, ntgl

      logical, intent(in)  :: uni_cld, lmfshal, lmfdeep2

      real (kind=kind_phys), dimension(:,:), intent(in) :: plvl, plyr,  &
     &       tlyr, qlyr, qstl, rhly, cldcov, delp, dz, dzlay,           &
     &       re_cloud, re_ice, re_snow
      real (kind=kind_phys), dimension(:), intent(inout) ::             &
     &       lwp_ex, iwp_ex, lwp_fc, iwp_fc

      real (kind=kind_phys), dimension(:,:,:), intent(in) :: clw

      real (kind=kind_phys), dimension(:),   intent(in) :: xlat, xlon,  &
     &       slmsk
      real(kind=kind_phys), dimension(:), intent(in) :: gridkm

!  --- inputs/outputs

      real (kind=kind_phys), dimension(:,:), intent(inout) ::            &
     &   cld_frac, cld_lwp, cld_reliq, cld_iwp, cld_reice,               &
     &   cld_rwp, cld_rerain, cld_swp, cld_resnow

!  ---  local variables:
      real (kind=kind_phys), dimension(IX,NLAY) :: cldtot, cldcnv,      &
     &       cwp, cip, crp, csp, rew, rei, res, rer

      real (kind=kind_phys), dimension(NLAY) :: cldfra1d, qv1d,         &
     &                                 qc1d, qi1d, qs1d, dz1d, p1d, t1d

      real (kind=kind_phys) :: clwmin, tem1
      real (kind=kind_phys) :: corr, xland, snow_mass_factor
      real (kind=kind_phys), parameter :: max_relh = 1.5
      real (kind=kind_phys), parameter :: snow_max_radius = 130.0

      integer :: i, k, k2, id, nf, idx_rei
!
!===> ... begin here
!

      clwmin = 1.0E-9

      do k = 1, NLAY
        do i = 1, IX
          cldtot(i,k) = 0.0
          cldcnv(i,k) = 0.0
          cwp   (i,k) = 0.0
          cip   (i,k) = 0.0
          crp   (i,k) = 0.0
          csp   (i,k) = 0.0
          rew   (i,k) = re_cloud(i,k)
          rei   (i,k) = re_ice(i,k)
          rer   (i,k) = rrain_def            ! default rain radius to 1000 micron
          res   (i,k) = re_snow(i,K)
        enddo
      enddo

!> - Compute cloud liquid/ice condensate path in \f$ g/m^2 \f$ .
!> - Since using Thompson MP, assume 1 percent of snow is actually in
!!   ice sizes.

      do k = 1, NLAY-1
        do i = 1, IX
          cwp(i,k) = max(0.0, clw(i,k,ntcw) * dz(i,k)*1.E6)
          crp(i,k) = 0.0
          snow_mass_factor = 0.90
          cip(i,k) = max(0.0, (clw(i,k,ntiw)                            &
     &             + (1.0-snow_mass_factor)*clw(i,k,ntsw))*dz(i,k)*1.E6)
          if (re_snow(i,k) .gt. snow_max_radius)then
             snow_mass_factor = min(snow_mass_factor,                   &
     &                              (snow_max_radius/re_snow(i,k))      &
     &                             *(snow_max_radius/re_snow(i,k)))
             res(i,k) = snow_max_radius
          endif
          csp(i,k) = max(0.,snow_mass_factor*clw(i,k,ntsw)*dz(i,k)*1.E6)
        enddo
      enddo

!> - Sum the liquid water and ice paths that come from explicit micro

      do i = 1, IX
         lwp_ex(i) = 0.0
         iwp_ex(i) = 0.0
         do k = 1, NLAY-1
            lwp_ex(i) = lwp_ex(i) + cwp(i,k)
            iwp_ex(i) = iwp_ex(i) + cip(i,k) + csp(i,k)
         enddo
      enddo

!> - Now determine the cloud fraction.  Here, we will use the scheme of
!!   G. Thompson that implements a variannt of Mocko and Cotton (1995)
!!   based on work within HWRF and WRF.  Where the bulk microphysics
!!   scheme already has explicit clouds, assume cloud fraction of one,
!!   but, otherwise, use a Sundqvist et al (1989) scheme and RH-critical
!!   to account for sub-grid-scale clouds, include those in the water
!!   and ice paths _seen_ by the radiation scheme, but do not actually
!!   include these fake clouds into anything other than radiation.

      do i = 1, IX
         if (slmsk(i)-0.5 .gt. 0.5 .and. slmsk(i)+0.5 .lt. 1.5) then
            xland = 1.0
         else
            xland = 2.0
         endif

         cldfra1d(:) = 0.0

         if (ivflip .eq. 1) then
            do k = 1, NLAY
               qv1d(k) = qlyr(i,k)
               qc1d(k) = max(0.0, clw(i,k,ntcw))
               qi1d(k) = max(0.0, clw(i,k,ntiw))
               qs1d(k) = max(0.0, clw(i,k,ntsw))
               dz1d(k) = dz(i,k)*1.E3
               p1d(k) = plyr(i,k)*100.0
               t1d(k) = tlyr(i,k)
            enddo
         else
            do k = NLAY, 1, -1
               k2 = NLAY - k + 1
               qv1d(k2) = qlyr(i,k)
               qc1d(k2) = max(0.0, clw(i,k,ntcw))
               qi1d(k2) = max(0.0, clw(i,k,ntiw))
               qs1d(k2) = max(0.0, clw(i,k,ntsw))
               dz1d(k2) = dz(i,k)*1.E3
               p1d(k2) = plyr(i,k)*100.0
               t1d(k2) = tlyr(i,k)
            enddo
         endif

         call cal_cldfra3(cldfra1d, qv1d, qc1d, qi1d, qs1d, dz1d,       &
     &                    p1d, t1d, xland, gridkm(i),                   &
     &                    .false., max_relh, 1, nlay, .false.)

         do k = 1, NLAY
            cldtot(i,k) = cldfra1d(k)
            if (qc1d(k).gt.clwmin .and. cldfra1d(k).lt.ovcst) then
               cwp(i,k) = qc1d(k) * dz1d(k)*1000.
               if ((xland-1.5).GT.0.) then                               !--- Ocean
                  rew(i,k) = 9.5
               else                                                      !--- Land
                  rew(i,k) = 5.5
               endif 
            endif 
            if (qi1d(k).gt.clwmin .and. cldfra1d(k).lt.ovcst) then
               cip(i,k) = qi1d(k) * dz1d(k)*1000.
               idx_rei = int(t1d(k)-179.)
               idx_rei = min(max(idx_rei,1),75)
               corr = t1d(k) - int(t1d(k))
               rei(i,K) = max(5.0, retab(idx_rei)*(1.-corr) +           &
     &                                 retab(idx_rei+1)*corr)
            endif 
         enddo
      enddo

      do k = 1, NLAY
        do i = 1, IX
          cld_frac(i,k)   = cldtot(i,k)
          cld_lwp(i,k)    = cwp(i,k)
          cld_reliq(i,k)  = rew(i,k)
          cld_iwp(i,k)    = cip(i,k)
          cld_reice(i,k)  = rei(i,k)
          cld_rwp(i,k)    = crp(i,k)  ! added for Thompson
          cld_rerain(i,k) = rer(i,k)
          cld_swp(i,k)    = csp(i,k)  ! added for Thompson
          cld_resnow(i,k) = res(i,k)
        enddo
      enddo

!> - Sum the liquid water and ice paths that come from fractional clouds

      do i = 1, IX
         lwp_fc(i) = 0.0
         iwp_fc(i) = 0.0
         do k = 1, NLAY
            lwp_fc(i) = lwp_fc(i) + cwp(i,k)
            iwp_fc(i) = iwp_fc(i) + cip(i,k) + csp(i,k)
         enddo
         lwp_fc(i) = MAX(0.0, lwp_fc(i) - lwp_ex(i))
         iwp_fc(i) = MAX(0.0, iwp_fc(i) - iwp_ex(i))
         lwp_fc(i) = lwp_fc(i)*1.E-3
         iwp_fc(i) = iwp_fc(i)*1.E-3
         lwp_ex(i) = lwp_ex(i)*1.E-3
         iwp_ex(i) = iwp_ex(i)*1.E-3
      enddo
!
      return

!............................................
      end subroutine progcld_thompson
!............................................
!mz


!> \ingroup module_radiation_clouds
!> This subroutine computes cloud related quantities using
!! for unified cloud microphysics scheme.
!>\section progclduni General Algorithm
!> @{
      subroutine progclduni                                             &
     &     ( plyr,plvl,tlyr,tvly,ccnd,ncnd,                             &    !  ---  inputs:
     &       xlat,xlon,slmsk,dz,delp, IX, NLAY, NLP1, cldtot,           &
     &       effrl,effri,effrr,effrs,effr_in,                           &
     &       dzlay, cldtot1, cldcnv,                                     &
     &       cld_frac, cld_lwp, cld_reliq, cld_iwp,                     & !  ---  outputs
     &       cld_reice,cld_rwp, cld_rerain,cld_swp, cld_resnow          &
     &      )

! =================   subprogram documentation block   ================ !
!                                                                       !
! subprogram:    progclduni    computes cloud related quantities using  !
!   for unified cloud microphysics scheme.                !
!                                                                       !
! abstract:  this program computes cloud fractions from cloud           !
!   condensates, calculates liquid/ice cloud droplet effective radius,  !
!   and computes the low, mid, high, total and boundary layer cloud     !
!   fractions and the vertical indices of low, mid, and high cloud      !
!   top and base.  the three vertical cloud domains are set up in the   !
!   initial subroutine "cld_init".                                      !
!   This program is written by Moorthi                                  !
!   to represent unified cloud across all physics while                 !
!   using SHOC+MG2/3+convection (RAS or SAS or CSAW)                    !
!                                                                       !
! usage:         call progclduni                                        !
!                                                                       !
! subprograms called:   gethml                                          !
!                                                                       !
! attributes:                                                           !
!   language:   fortran 90                                              !
!   machine:    ibm-sp, sgi                                             !
!                                                                       !
!                                                                       !
!  ====================  definition of variables  ====================  !
!                                                                       !
! input variables:                                                      !
!   plyr  (IX,NLAY)      : model layer mean pressure in mb (100Pa)           !
!   plvl  (IX,NLP1)      : model level pressure in mb (100Pa)                !
!   tlyr  (IX,NLAY)      : model layer mean temperature in k                 !
!   tvly  (IX,NLAY)      : model layer virtual temperature in k              !
!   ccnd  (IX,NLAY,ncnd) : layer cloud condensate amount                     !
!                          water, ice, rain, snow (+ graupel)                !
!   ncnd                 : number of layer cloud condensate types (max of 4) !
!   xlat  (IX)           : grid latitude in radians, default to pi/2 -> -pi/2!
!                          range, otherwise see in-line comment              !
!   xlon  (IX)           : grid longitude in radians  (not used)             !
!   slmsk (IX)           : sea/land mask array (sea:0,land:1,sea-ice:2)      !
!   IX                   : horizontal dimention                              !
!   NLAY,NLP1            : vertical layer/level dimensions                   !
!   cldtot               : unified cloud fracrion from moist physics         !
!   effrl (ix,nlay)      : effective radius for liquid water                 !
!   effri (ix,nlay)      : effective radius for ice water                    !
!   effrr (ix,nlay)      : effective radius for rain water                   !
!   effrs (ix,nlay)      : effective radius for snow water                   !
!   effr_in              : logical - if .true. use input effective radii     !
!   dz    (ix,nlay)      : layer thickness (km)                              !
!   delp  (ix,nlay)      : model layer pressure thickness in mb (100Pa)      !
!   dzlay(ix,nlay)  : thickness between model layer centers (km)        !
!                                                                       !
! output variables:                                                     !
!   cloud profiles:                                                     !
!      cld_frac  (:,:) - layer total cloud fraction                     !
!      cld_lwp   (:,:) - layer cloud liq water path       (g/m**2)      !
!      cld_reliq (:,:) - mean eff radius for liq cloud    (micron)      !
!      cld_iwp   (:,:) - layer cloud ice water path       (g/m**2)      !
!      cld_reice (:,:) - mean eff radius for ice cloud    (micron)      !
!      cld_rwp   (:,:) - layer rain drop water path       not assigned  !
!      cld_rerain(:,:) - mean eff radius for rain drop    (micron)      !
!  *** cld_swp   (:,:) - layer snow flake water path      not assigned  !
!      cld_resnow(:,:) - mean eff radius for snow flake   (micron)      !
!  *** fu's scheme need to be normalized by snow density (g/m**3/1.0e6) !
!   clds  (IX,5)    : fraction of clouds for low, mid, hi, tot, bl      !
!   mtop  (IX,3)    : vertical indices for low, mid, hi cloud tops      !
!   mbot  (IX,3)    : vertical indices for low, mid, hi cloud bases     !
!   de_lgth(ix)     : clouds decorrelation length (km)                  !
!   alpha(ix,nlay)  : alpha decorrelation parameter
!                                                                       !
! module variables:                                                     !
!   ivflip          : control flag of vertical index direction          !
!                     =0: index from toa to surface                     !
!                     =1: index from surface to toa                     !
!   lmfshal         : mass-flux shallow conv scheme flag                !
!   lmfdeep2        : scale-aware mass-flux deep conv scheme flag       !
!   lcrick          : control flag for eliminating CRICK                !
!                     =t: apply layer smoothing to eliminate CRICK      !
!                     =f: do not apply layer smoothing                  !
!   lcnorm          : control flag for in-cld condensate                !
!                     =t: normalize cloud condensate                    !
!                     =f: not normalize cloud condensate                !
!                                                                       !
!  ====================    end of description    =====================  !
!
      implicit none

!  ---  inputs
      integer,  intent(in) :: IX, NLAY, NLP1, ncnd
      logical,  intent(in) :: effr_in

      real (kind=kind_phys), dimension(:,:,:), intent(in) :: ccnd
      real (kind=kind_phys), dimension(:,:),   intent(in) :: plvl, plyr,&
     &       tlyr, tvly, cldtot, effrl, effri, effrr, effrs, dz, delp,  &
     &       dzlay

      real (kind=kind_phys), dimension(:),   intent(in) :: xlat, xlon,  &
     &       slmsk

      real (kind=kind_phys), dimension(:,:), intent(inout) :: cldtot1

!  --- inputs/outputs

      real (kind=kind_phys), dimension(:,:), intent(inout) ::            &
     &   cld_frac, cld_lwp, cld_reliq, cld_iwp, cld_reice,               &
     &   cld_rwp, cld_rerain, cld_swp, cld_resnow

!  ---  local variables:
      real (kind=kind_phys), dimension(IX,NLAY) :: cldcnv, cwp, cip,    &
     &       crp, csp, rew, rei, res, rer
      real (kind=kind_phys), dimension(IX,NLAY,ncnd) :: cndf

      real (kind=kind_phys) :: tem1, tem2, tem3

      integer :: i, k, id, nf, n

!
!===> ... begin here
!
      do k = 1, NLAY
        do i = 1, IX
          cldcnv(i,k) = 0.0
          cwp(i,k)    = 0.0
          cip(i,k)    = 0.0
          crp(i,k)    = 0.0
          csp(i,k)    = 0.0
        enddo
      enddo
      do n=1,ncnd
        do k = 1, NLAY
          do i = 1, IX
            cndf(i,k,n) = ccnd(i,k,n)
          enddo
        enddo
      enddo
      if ( lcrick ) then   ! vertical smoorthing
        do n=1,ncnd
          do i = 1, IX
            cndf(i,1,n)    = 0.75*ccnd(i,1,n)    + 0.25*ccnd(i,2,n)
            cndf(i,nlay,n) = 0.75*ccnd(i,nlay,n) + 0.25*ccnd(i,nlay-1,n)
          enddo
          do k = 2, NLAY-1
            do i = 1, IX
              cndf(i,K,n) = 0.25 * (ccnd(i,k-1,n) + ccnd(i,k+1,n))      &
     &                    + 0.5  *  ccnd(i,k,n)
            enddo
          enddo
        enddo
      endif

!> -# Compute cloud liquid/ice condensate path in \f$ g/m^2 \f$ .

      if (ncnd == 2) then
        do k = 1, NLAY
          do i = 1, IX
            tem1      = gfac * delp(i,k)
            cwp(i,k)  = cndf(i,k,1) * tem1
            cip(i,k)  = cndf(i,k,2) * tem1
          enddo
        enddo
      elseif (ncnd == 4) then
        do k = 1, NLAY
          do i = 1, IX
            tem1      = gfac * delp(i,k)
            cwp(i,k)  = cndf(i,k,1) * tem1
            cip(i,k)  = cndf(i,k,2) * tem1
            crp(i,k)  = cndf(i,k,3) * tem1
            csp(i,k)  = cndf(i,k,4) * tem1
          enddo
        enddo
      endif

      do k = 1, NLAY
        do i = 1, IX
          if (cldtot(i,k) < climit) then
            cwp(i,k)    = 0.0
            cip(i,k)    = 0.0
            crp(i,k)    = 0.0
            csp(i,k)    = 0.0
          endif
        enddo
      enddo

      if ( lcnorm ) then
        do k = 1, NLAY
          do i = 1, IX
            if (cldtot(i,k) >= climit) then
              tem1 = 1.0 / max(climit2, cldtot(i,k))
              cwp(i,k) = cwp(i,k) * tem1
              cip(i,k) = cip(i,k) * tem1
              crp(i,k) = crp(i,k) * tem1
              csp(i,k) = csp(i,k) * tem1
            endif
          enddo
        enddo
      endif

!     assign/calculate efective radii for cloud water, ice, rain, snow

      if (effr_in) then
        do k = 1, NLAY
          do i = 1, IX
            rew(i,k) = effrl (i,k)
            rei(i,k) = max(10.0, min(150.0,effri (i,k)))
            rer(i,k) = effrr (i,k)
            res(i,k) = effrs (i,k)
          enddo
        enddo
      else
        do k = 1, NLAY
          do i = 1, IX
            rew(i,k) = reliq_def            ! default liq  radius to 10   micron
            rei(i,k) = reice_def            ! default ice  radius to 50   micron
            rer(i,k) = rrain_def            ! default rain radius to 1000 micron
            res(i,k) = rsnow_def            ! default snow radius to 250  micron
          enddo
        enddo
!> -# Compute effective liquid cloud droplet radius over land.
        do i = 1, IX
          if (nint(slmsk(i)) == 1) then
            do k = 1, NLAY
              tem1     = min(1.0, max(0.0, (con_ttp-tlyr(i,k))*0.05))
              rew(i,k) = 5.0 + 5.0 * tem1
            enddo
          endif
        enddo

!> -# Compute effective ice cloud droplet radius following Heymsfield
!!    and McFarquhar (1996) \cite heymsfield_and_mcfarquhar_1996.

        do k = 1, NLAY
          do i = 1, IX
            tem2 = tlyr(i,k) - con_ttp

            if (cip(i,k) > 0.0) then
              tem3 = gord * cip(i,k) * plyr(i,k) / (delp(i,k)*tvly(i,k))

              if (tem2 < -50.0) then
                rei(i,k) = (1250.0/9.917) * tem3 ** 0.109
              elseif (tem2 < -40.0) then
                rei(i,k) = (1250.0/9.337) * tem3 ** 0.08
              elseif (tem2 < -30.0) then
                rei(i,k) = (1250.0/9.208) * tem3 ** 0.055
              else
                rei(i,k) = (1250.0/9.387) * tem3 ** 0.031
              endif
!             rei(i,k)   = max(20.0, min(rei(i,k), 300.0))
!             rei(i,k)   = max(10.0, min(rei(i,k), 100.0))
              rei(i,k)   = max(10.0, min(rei(i,k), 150.0))
!             rei(i,k)   = max(5.0,  min(rei(i,k), 130.0))
            endif
          enddo
        enddo
      endif

      do k = 1, NLAY
        do i = 1, IX
          cldtot1(i,k) = cldtot(i,k)
        enddo
      enddo
!
      do k = 1, NLAY
        do i = 1, IX
          cld_frac(i,k)   = cldtot(i,k)
          cld_lwp(i,k)    = cwp(i,k)
          cld_reliq(i,k)  = rew(i,k)
          cld_iwp(i,k)    = cip(i,k)
          cld_reice(i,k)  = rei(i,k)
          cld_rwp(i,k)    = crp(i,k)  ! added for Thompson
          cld_rerain(i,k) = rer(i,k)
          cld_swp(i,k)    = csp(i,k)  ! added for Thompson
          cld_resnow(i,k) = res(i,k)
        enddo
      enddo
!
      return
!...................................
      end subroutine progclduni
!-----------------------------------
!> @}

!> \ingroup module_radiation_clouds
!> This subroutine computes high, mid, low, total, and boundary cloud
!! fractions and cloud top/bottom layer indices for model diagnostic
!! output. The three cloud domain boundaries are defined by ptopc. The
!! cloud overlapping method is defined by control flag 'iovr', which is
!! also used by LW and SW radiation programs.
!> \param plyr    (IX,NLAY), model layer mean pressure in mb (100Pa)
!> \param ptop1   (IX,4), pressure limits of cloud domain interfaces
!!                    (sfc,low,mid,high) in mb (100Pa)
!> \param cldtot  (IX,NLAY), total or stratiform cloud profile in fraction
!> \param cldcnv  (IX,NLAY), convective cloud (for diagnostic scheme only)
!> \param dz      (IX,NLAY), layer thickness (km)
!> \param de_lgth (IX),  clouds decorrelation length (km)
!> \param alpha   (IX,NLAY), alpha decorrelation parameter
!> \param IX      horizontal dimension
!> \param NLAY    vertical layer dimensions
!> \param clds   (IX,5), fraction of clouds for low, mid, hi, tot, bl
!> \param mtop   (IX,3),vertical indices for low, mid, hi cloud tops
!> \param mbot   (IX,3),vertical indices for low, mid, hi cloud bases
!!
!>\section detail Detailed Algorithm
!! @{
      subroutine gethml                                                 &
     &     ( plyr, ptop1, cldtot, cldcnv, dz, de_lgth, alpha,           &       !  ---  inputs:
     &       IX, NLAY, iovr_rand, iovr_maxrand, iovr_max,               &
     &       iovr_dcorr, iovr_exp, iovr_exprand,                        &
     &       clds, mtop, mbot                                           &       !  ---  outputs:
     &     )

!  ===================================================================  !
!                                                                       !
! abstract: compute high, mid, low, total, and boundary cloud fractions !
!   and cloud top/bottom layer indices for model diagnostic output.     !
!   the three cloud domain boundaries are defined by ptopc.  the cloud  !
!   overlapping method is defined by control flag 'iovr', which is also !
!   used by lw and sw radiation programs.                               !
!                                                                       !
! usage:         call gethml                                            !
!                                                                       !
! subprograms called:  none                                             !
!                                                                       !
! attributes:                                                           !
!   language:   fortran 90                                              !
!   machine:    ibm-sp, sgi                                             !
!                                                                       !
!                                                                       !
!  ====================  definition of variables  ====================  !
!                                                                       !
! input variables:                                                      !
!   plyr  (IX,NLAY) : model layer mean pressure in mb (100Pa)           !
!   ptop1 (IX,4)    : pressure limits of cloud domain interfaces        !
!                     (sfc,low,mid,high) in mb (100Pa)                  !
!   cldtot(IX,NLAY) : total or straiform cloud profile in fraction      !
!   cldcnv(IX,NLAY) : convective cloud (for diagnostic scheme only)     !
!   dz    (ix,nlay) : layer thickness (km)                              !
!   de_lgth(ix)     : clouds vertical de-correlation length (km)        !
!   alpha(ix,nlay)  : alpha decorrelation parameter
!   IX              : horizontal dimention                              !
!   NLAY            : vertical layer dimensions                         !
!                                                                       !
! output variables:                                                     !
!   clds  (IX,5)    : fraction of clouds for low, mid, hi, tot, bl      !
!   mtop  (IX,3)    : vertical indices for low, mid, hi cloud tops      !
!   mbot  (IX,3)    : vertical indices for low, mid, hi cloud bases     !
!                                                                       !
! external module variables:  (in physparam)                            !
!   ivflip          : control flag of vertical index direction          !
!                     =0: index from toa to surface                     !
!                     =1: index from surface to toa                     !
!                                                                       !
! internal module variables:                                            !
!   iovr            : control flag for cloud overlap                    !
!                     =0 random overlapping clouds                      !
!                     =1 max/ran overlapping clouds                     !
!                     =2 maximum overlapping  ( for mcica only )        !
!                     =3 decorr-length ovlp   ( for mcica only )        !
!                     =4: exponential cloud overlap  (AER; mcica only)  !
!                     =5: exponential-random overlap (AER; mcica only)  !
!                                                                       !
!  ====================    end of description    =====================  !
!
      implicit none!

!  ---  inputs:
      integer, intent(in) :: IX, NLAY
      integer, intent(in) ::                                            &
     &     iovr_rand,                    ! Flag for random cloud overlap method
     &     iovr_maxrand,                 ! Flag for maximum-random cloud overlap method
     &     iovr_max,                     ! Flag for maximum cloud overlap method
     &     iovr_dcorr,                   ! Flag for decorrelation-length cloud overlap method
     &     iovr_exp,                     ! Flag for exponential cloud overlap method
     &     iovr_exprand                  ! Flag for exponential-random cloud overlap method

      real (kind=kind_phys), dimension(:,:), intent(in) :: plyr, ptop1, &
     &       cldtot, cldcnv, dz
      real (kind=kind_phys), dimension(:),   intent(in) :: de_lgth
      real (kind=kind_phys), dimension(:,:), intent(in) :: alpha

!  ---  outputs
      real (kind=kind_phys), dimension(:,:), intent(out) :: clds

      integer,               dimension(:,:), intent(out) :: mtop, mbot

!  ---  local variables:
      real (kind=kind_phys) :: cl1(IX), cl2(IX), dz1(ix)
      real (kind=kind_phys) :: pcur, pnxt, ccur, cnxt, alfa

      integer, dimension(IX):: idom, kbt1, kth1, kbt2, kth2
      integer :: i, k, id, id1, kstr, kend, kinc

!
!===> ... begin here
!
      clds(:,:) = 0.0

      do i = 1, IX
        cl1(i) = 1.0
        cl2(i) = 1.0
      enddo

!  ---  total and bl clouds, where cl1, cl2 are fractions of clear-sky view
!       layer processed from surface and up

!> - Calculate total and BL cloud fractions (maximum-random cloud
!!    overlapping is operational).

      if ( ivflip == 0 ) then                   ! input data from toa to sfc
        kstr = NLAY
        kend = 1
        kinc = -1
      else                                      ! input data from sfc to toa
        kstr = 1
        kend = NLAY
        kinc = 1
      endif                                     ! end_if_ivflip

      if ( iovr == iovr_rand ) then                     ! random overlap

        do k = kstr, kend, kinc
          do i = 1, IX
            ccur = min( ovcst, max( cldtot(i,k), cldcnv(i,k) ))
            if (ccur >= climit) cl1(i) = cl1(i) * (1.0 - ccur)
          enddo

          if (k == llyr) then
            do i = 1, IX
              clds(i,5) = 1.0 - cl1(i)          ! save bl cloud
            enddo
          endif
        enddo

        do i = 1, IX
          clds(i,4) = 1.0 - cl1(i)              ! save total cloud
        enddo

      elseif ( iovr == iovr_maxrand ) then                 ! max/ran overlap

        do k = kstr, kend, kinc
          do i = 1, IX
            ccur = min( ovcst, max( cldtot(i,k), cldcnv(i,k) ))
            if (ccur >= climit) then             ! cloudy layer
              cl2(i) = min( cl2(i), (1.0 - ccur) )
            else                                ! clear layer
              cl1(i) = cl1(i) * cl2(i)
              cl2(i) = 1.0
            endif
          enddo

          if (k == llyr) then
            do i = 1, IX
              clds(i,5) = 1.0 - cl1(i) * cl2(i) ! save bl cloud
            enddo
          endif
        enddo

        do i = 1, IX
          clds(i,4) = 1.0 - cl1(i) * cl2(i)     ! save total cloud
        enddo

      elseif ( iovr == iovr_max ) then                 ! maximum overlap all levels

        cl1(:) = 0.0

        do k = kstr, kend, kinc
          do i = 1, IX
            ccur = min( ovcst,  max( cldtot(i,k), cldcnv(i,k) ))
            if (ccur >= climit) cl1(i) = max( cl1(i), ccur )
          enddo

          if (k == llyr) then
            do i = 1, IX
              clds(i,5) = cl1(i)    ! save bl cloud
            enddo
          endif
        enddo

        do i = 1, IX
          clds(i,4) = cl1(i)        ! save total cloud
        enddo

      elseif ( iovr == iovr_dcorr ) then                 ! random if clear-layer divided,
                                                ! otherwise de-corrlength method
        do i = 1, ix
          dz1(i) = - dz(i,kstr)
        enddo

        do k = kstr, kend, kinc
          do i = 1, ix
            ccur = min( ovcst, max( cldtot(i,k), cldcnv(i,k) ))
            if (ccur >= climit) then                           ! cloudy layer
              alfa = exp( -0.5*((dz1(i)+dz(i,k)))/de_lgth(i) )
              dz1(i) = dz(i,k)
              cl2(i) =    alfa      * min(cl2(i), (1.0 - ccur))         & ! maximum part
     &               + (1.0 - alfa) * (cl2(i) * (1.0 - ccur))             ! random part
            else                                               ! clear layer
              cl1(i) = cl1(i) * cl2(i)
              cl2(i) = 1.0
              if (k /= kend) dz1(i) = -dz(i,k+kinc)
            endif
          enddo

          if (k == llyr) then
            do i = 1, ix
              clds(i,5) = 1.0 - cl1(i) * cl2(i) ! save bl cloud
            enddo
          endif
        enddo

        do i = 1, ix
          clds(i,4) = 1.0 - cl1(i) * cl2(i)     ! save total cloud
        enddo

      elseif ( iovr == iovr_exp .or. iovr == iovr_exprand ) then  ! exponential overlap (iovr=4), or
                                                ! exponential-random  (iovr=5);
                                                ! distinction defined by alpha

        do k = kstr, kend, kinc
          do i = 1, ix
            ccur = min( ovcst, max( cldtot(i,k), cldcnv(i,k) ))
            if (ccur >= climit) then                           ! cloudy layer
              cl2(i) =   alpha(i,k) * min(cl2(i), (1.0 - ccur))          & ! maximum part
     &               + (1.0 - alpha(i,k)) * (cl2(i) * (1.0 - ccur))        ! random part
            else                                               ! clear layer
              cl1(i) = cl1(i) * cl2(i)
              cl2(i) = 1.0
            endif
          enddo

          if (k == llyr) then
            do i = 1, ix
              clds(i,5) = 1.0 - cl1(i) * cl2(i) ! save bl cloud
            enddo
          endif
        enddo

        do i = 1, ix
          clds(i,4) = 1.0 - cl1(i) * cl2(i)     ! save total cloud
        enddo

      endif                                     ! end_if_iovr

!  ---  high, mid, low clouds, where cl1, cl2 are cloud fractions
!       layer processed from one layer below llyr and up
!  ---  change! layer processed from surface to top, so low clouds will
!       contains both bl and low clouds.

!> - Calculte high, mid, low cloud fractions and vertical indices of
!!    cloud tops/bases.
      if ( ivflip == 0 ) then                   ! input data from toa to sfc

        do i = 1, IX
          cl1 (i) = 0.0
          cl2 (i) = 0.0
          kbt1(i) = NLAY
          kbt2(i) = NLAY
          kth1(i) = 0
          kth2(i) = 0
          idom(i) = 1
          mbot(i,1) = NLAY
          mtop(i,1) = NLAY
          mbot(i,2) = NLAY - 1
          mtop(i,2) = NLAY - 1
          mbot(i,3) = NLAY - 1
          mtop(i,3) = NLAY - 1
        enddo

!org    do k = llyr-1, 1, -1
        do k = NLAY, 1, -1
          do i = 1, IX
            id = idom(i)
            id1= id + 1

            pcur = plyr(i,k)
            ccur = min( ovcst, max( cldtot(i,k), cldcnv(i,k) ))

            if (k > 1) then
              pnxt = plyr(i,k-1)
              cnxt = min( ovcst, max( cldtot(i,k-1), cldcnv(i,k-1) ))
            else
              pnxt = -1.0
              cnxt = 0.0
            endif

            if (pcur < ptop1(i,id1)) then
              id = id + 1
              id1= id1 + 1
              idom(i) = id
            endif

            if (ccur >= climit) then
              if (kth2(i) == 0) kbt2(i) = k
              kth2(i) = kth2(i) + 1

              if ( iovr == iovr_rand ) then
                cl2(i) = cl2(i) + ccur - cl2(i)*ccur
              else
                cl2(i) = max( cl2(i), ccur )
              endif

              if (cnxt < climit .or. pnxt < ptop1(i,id1)) then
                kbt1(i) = nint( (cl1(i)*kbt1(i) + cl2(i)*kbt2(i) )      &
     &                  / (cl1(i) + cl2(i)) )
                kth1(i) = nint( (cl1(i)*kth1(i) + cl2(i)*kth2(i) )      &
     &                  / (cl1(i) + cl2(i)) )
                cl1 (i) = cl1(i) + cl2(i) - cl1(i)*cl2(i)

                kbt2(i) = k - 1
                kth2(i) = 0
                cl2 (i) = 0.0
              endif   ! end_if_cnxt_or_pnxt
            endif     ! end_if_ccur

            if (pnxt < ptop1(i,id1)) then
              clds(i,id) = cl1(i)
              mtop(i,id) = min( kbt1(i), kbt1(i)-kth1(i)+1 )
              mbot(i,id) = kbt1(i)

              cl1 (i) = 0.0
              kbt1(i) = k - 1
              kth1(i) = 0

              if (id1 <= NK_CLDS) then
                mbot(i,id1) = kbt1(i)
                mtop(i,id1) = kbt1(i)
              endif
            endif     ! end_if_pnxt

          enddo       ! end_do_i_loop
        enddo         ! end_do_k_loop

      else                                      ! input data from sfc to toa

        do i = 1, IX
          cl1 (i) = 0.0
          cl2 (i) = 0.0
          kbt1(i) = 1
          kbt2(i) = 1
          kth1(i) = 0
          kth2(i) = 0
          idom(i) = 1
          mbot(i,1) = 1
          mtop(i,1) = 1
          mbot(i,2) = 2
          mtop(i,2) = 2
          mbot(i,3) = 2
          mtop(i,3) = 2
        enddo

!org    do k = llyr+1, NLAY
        do k = 1, NLAY
          do i = 1, IX
            id = idom(i)
            id1= id + 1

            pcur = plyr(i,k)
            ccur = min( ovcst, max( cldtot(i,k), cldcnv(i,k) ))

            if (k < NLAY) then
              pnxt = plyr(i,k+1)
              cnxt = min( ovcst, max( cldtot(i,k+1), cldcnv(i,k+1) ))
            else
              pnxt = -1.0
              cnxt = 0.0
            endif

            if (pcur < ptop1(i,id1)) then
              id = id + 1
              id1= id1 + 1
              idom(i) = id
            endif

            if (ccur >= climit) then
              if (kth2(i) == 0) kbt2(i) = k
              kth2(i) = kth2(i) + 1

              if ( iovr == iovr_rand ) then
                cl2(i) = cl2(i) + ccur - cl2(i)*ccur
              else
                cl2(i) = max( cl2(i), ccur )
              endif

              if (cnxt < climit .or. pnxt < ptop1(i,id1)) then
                kbt1(i) = nint( (cl1(i)*kbt1(i) + cl2(i)*kbt2(i))       &
     &                  / (cl1(i) + cl2(i)) )
                kth1(i) = nint( (cl1(i)*kth1(i) + cl2(i)*kth2(i))       &
     &                  / (cl1(i) + cl2(i)) )
                cl1 (i) = cl1(i) + cl2(i) - cl1(i)*cl2(i)

                kbt2(i) = k + 1
                kth2(i) = 0
                cl2 (i) = 0.0
              endif     ! end_if_cnxt_or_pnxt
            endif       ! end_if_ccur

            if (pnxt < ptop1(i,id1)) then
              clds(i,id) = cl1(i)
              mtop(i,id) = max( kbt1(i), kbt1(i)+kth1(i)-1 )
              mbot(i,id) = kbt1(i)

              cl1 (i) = 0.0
              kbt1(i) = min(k+1, nlay)
              kth1(i) = 0

              if (id1 <= NK_CLDS) then
                mbot(i,id1) = kbt1(i)
                mtop(i,id1) = kbt1(i)
              endif
            endif     ! end_if_pnxt

          enddo       ! end_do_i_loop
        enddo         ! end_do_k_loop

      endif                                     ! end_if_ivflip

!
      return
!...................................
      end subroutine gethml
!-----------------------------------
!! @}

!+---+-----------------------------------------------------------------+
!..Cloud fraction scheme by G. Thompson (NCAR-RAL), not intended for
!.. combining with any cumulus or shallow cumulus parameterization
!.. scheme cloud fractions.  This is intended as a stand-alone for
!.. cloud fraction and is relatively good at getting widespread stratus
!.. and stratoCu without caring whether any deep/shallow Cu param schemes
!.. is making sub-grid-spacing clouds/precip.  Under the hood, this
!.. scheme follows Mocko and Cotton (1995) in application of the
!.. Sundqvist et al (1989) scheme but using a grid-scale dependent
!.. RH threshold, one each for land v. ocean points based on
!.. experiences with HWRF testing.
!+---+-----------------------------------------------------------------+
!
!+---+-----------------------------------------------------------------+

      SUBROUTINE cal_cldfra3(CLDFRA, qv, qc, qi, qs, dz,                &
     &                 p, t, XLAND, gridkm,                             &
     &                 modify_qvapor, max_relh,                         &
     &                 kts,kte, debug_flag)
!
      USE module_mp_thompson   , ONLY : rsif, rslf
      IMPLICIT NONE
!
      INTEGER, INTENT(IN):: kts, kte
      LOGICAL, INTENT(IN):: modify_qvapor
      REAL, DIMENSION(kts:kte), INTENT(INOUT):: qv, qc, qi, cldfra
      REAL, DIMENSION(kts:kte), INTENT(IN):: p, t, dz, qs
      REAL, INTENT(IN):: gridkm, XLAND, max_relh
      LOGICAL, INTENT(IN):: debug_flag

!..Local vars.
      REAL:: RH_00L, RH_00O, RH_00
      REAL:: entrmnt=0.5
      INTEGER:: k
      REAL:: TC, qvsi, qvsw, RHUM, delz, var_temp
      REAL, DIMENSION(kts:kte):: qvs, rh, rhoa
      integer:: ndebug = 0

      character*512 dbg_msg

!+---+

!..Initialize cloud fraction, compute RH, and rho-air.

         DO k = kts,kte
            CLDFRA(K) = 0.0

            qvsw = rslf(P(k), t(k))
            qvsi = rsif(P(k), t(k))

            tc = t(k) - 273.15
            if (tc .ge. -12.0) then
               qvs(k) = qvsw
            elseif (tc .lt. -35.0) then
               qvs(k) = qvsi
            else
               qvs(k) = qvsw - (qvsw-qvsi)*(-12.0-tc)/(-12.0+35.)
            endif

            if (modify_qvapor) then
               if (qc(k).gt.1.E-8) then
                  qv(k) = MAX(qv(k), qvsw)
                  qvs(k) = qvsw
               endif
               if (qc(k).le.1.E-8 .and. qi(k).ge.1.E-9) then
                  qv(k) = MAX(qv(k), qvsi*1.005)    !..To ensure a tiny bit ice supersaturated
                  qvs(k) = qvsi
               endif
            endif

            rh(k) = MAX(0.01, qv(k)/qvs(k))
            rhoa(k) = p(k)/(287.0*t(k))

         ENDDO


!..First cut scale-aware. Higher resolution should require closer to
!.. saturated grid box for higher cloud fraction.  Simple functions
!.. chosen based on Mocko and Cotton (1995) starting point and desire
!.. to get near 100% RH as grid spacing moves toward 1.0km, but higher
!.. RH over ocean required as compared to over land.

      DO k = kts,kte

         delz = MAX(100., dz(k))
         RH_00L = 0.77+MIN(0.22,SQRT(1./(50.0+gridkm*gridkm*delz*0.01)))
         RH_00O = 0.85+MIN(0.14,SQRT(1./(50.0+gridkm*gridkm*delz*0.01)))
         RHUM = rh(k)

         if (qc(k).ge.1.E-6 .or. qi(k).ge.1.E-7                         &
     &                    .or. (qs(k).gt.1.E-6 .and. t(k).lt.273.)) then
            CLDFRA(K) = 1.0
         elseif (((qc(k)+qi(k)).gt.1.E-10) .and.                        &
     &                                    ((qc(k)+qi(k)).lt.1.E-6)) then
            var_temp = MIN(0.99, 0.1*(11.0 + log10(qc(k)+qi(k))))
            CLDFRA(K) = var_temp*var_temp
         else

            IF ((XLAND-1.5).GT.0.) THEN                                  !--- Ocean
               RH_00 = RH_00O
            ELSE                                                         !--- Land
               RH_00 = RH_00L
            ENDIF

            tc = MAX(-80.0, t(k) - 273.15)
            if (tc .lt. -24.0) RH_00 = RH_00L

            if (tc .gt. 20.0) then
               CLDFRA(K) = 0.0
            elseif (tc .ge. -24.0) then
               RHUM = MIN(rh(k), 1.0)
               var_temp = SQRT(SQRT((1.001-RHUM)/(1.001-RH_00)))
               CLDFRA(K) = MAX(0., 1.0-var_temp)
            else
               if (max_relh.gt.1.12 .or. (.NOT.(modify_qvapor)) ) then
!..For HRRR model, the following look OK.
                  RHUM = MIN(rh(k), 1.45)
                  RH_00 = RH_00 + (1.45-RH_00)*(-24.0-tc)/(-24.0+85.)
                  var_temp = SQRT(SQRT((1.46-RHUM)/(1.46-RH_00)))
                  CLDFRA(K) = MAX(0., 1.0-var_temp)
               else
!..but for the GFS model, RH is way lower.
                  RHUM = MIN(rh(k), 1.05)
                  RH_00 = RH_00 + (1.05-RH_00)*(-24.0-tc)/(-24.0+85.)
                  var_temp = SQRT(SQRT((1.06-RHUM)/(1.06-RH_00)))
                  CLDFRA(K) = MAX(0., 1.0-var_temp)
               endif
            endif
            if (CLDFRA(K).gt.0.) CLDFRA(K)=MAX(0.01,MIN(CLDFRA(K),0.99))

         endif
         if (cldfra(k).gt.0.0 .and. p(k).lt.7000.0) CLDFRA(K) = 0.0
      ENDDO

      call find_cloudLayers(qvs, cldfra, T, P, Dz, entrmnt,             &
     &                      debug_flag, qc, qi, qs, kts,kte)

!..Do a final total column adjustment since we may have added more than 1 mm
!.. LWP/IWP for multiple cloud decks.

      call adjust_cloudFinal(cldfra, qc, qi, rhoa, dz, kts,kte)

!..Intended for cold start model runs, we use modify_qvapor to ensure that cloudy
!.. areas are actually saturated such that the inserted clouds do not evaporate a
!.. timestep later.

      if (modify_qvapor) then
         DO k = kts,kte
            if (cldfra(k).gt.0.2 .and. cldfra(k).lt.1.0) then
               qv(k) = MAX(qv(k),qvs(k))
            endif
         ENDDO
      endif


      END SUBROUTINE cal_cldfra3

!+---+-----------------------------------------------------------------+
!..From cloud fraction array, find clouds of multi-level depth and compute
!.. a reasonable value of LWP or IWP that might be contained in that depth,
!.. unless existing LWC/IWC is already there.

      SUBROUTINE find_cloudLayers(qvs1d, cfr1d, T1d, P1d, Dz1d, entrmnt,&
     &                            debugfl, qc1d, qi1d, qs1d, kts,kte)
!
      IMPLICIT NONE
!
      INTEGER, INTENT(IN):: kts, kte
      LOGICAL, INTENT(IN):: debugfl
      REAL, INTENT(IN):: entrmnt
      REAL, DIMENSION(kts:kte), INTENT(IN):: qs1d,qvs1d,T1d,P1d,Dz1d
      REAL, DIMENSION(kts:kte), INTENT(INOUT):: cfr1d, qc1d, qi1d

!..Local vars.
      REAL, DIMENSION(kts:kte):: theta
      REAL:: theta1, theta2, delz
      INTEGER:: k, k2, k_tropo, k_m12C, k_cldb, k_cldt, kbot, k_p200
      LOGICAL:: in_cloud
      character*512 dbg_msg

!+---+

      k_m12C = 0
      k_p200 = 0
      DO k = kte, kts, -1
         theta(k) = T1d(k)*((100000.0/P1d(k))**(287.05/1004.))
         if (T1d(k)-273.16 .gt. -12.0 .and. P1d(k).gt.10100.0)          &
     &                   k_m12C = MAX(k_m12C, k)
         if (P1d(k).gt.19999.0 .and. k_p200.eq.0) k_p200 = k
      ENDDO
      if (k_m12C .le. kts) k_m12C = kts

!..Find tropopause height, best surrogate, because we would not really
!.. wish to put fake clouds into the stratosphere.  The 10/1500 ratio
!.. d(Theta)/d(Z) approximates a vertical line on typical SkewT chart
!.. near typical (mid-latitude) tropopause height.  Since messy data
!.. could give us a false signal of such a transition, do the check over 
!.. three K-level change, not just a level-to-level check.  This method
!.. has potential failure in arctic-like conditions with extremely low
!.. tropopause height, as would any other diagnostic, so ensure resulting
!.. k_tropo level is above 700hPa.

      if ( (kte-k_p200) .lt. 3) k_p200 = kte-3
      DO k = k_p200-2, kts, -1
         theta1 = theta(k)
         theta2 = theta(k+2)
         delz = 0.5*dz1d(k) + dz1d(k+1) + 0.5*dz1d(k+2)
         if ( (((theta2-theta1)/delz).lt.10./1500.) .OR.                &
     &                       P1d(k).gt.70000.) EXIT
      ENDDO
      k_tropo = MAX(kts+2, MIN(k+2, kte-1))

      if (k_tropo .gt. k_p200) then
         DO k = kte-3, k_p200-2, -1
            theta1 = theta(k)
            theta2 = theta(k+2)
            delz = 0.5*dz1d(k) + dz1d(k+1) + 0.5*dz1d(k+2)
            if ( (((theta2-theta1)/delz).lt.10./1500.) .AND.            &
     &                                    P1d(k).gt.9000.) EXIT
         ENDDO
         k_tropo = MAX(k_p200-1, MIN(k+2, kte-1))
      endif

!..Eliminate possible fractional clouds above supposed tropopause.
      DO k = k_tropo+1, kte
         if (cfr1d(k).gt.0.0 .and. cfr1d(k).lt.1.0) then
            cfr1d(k) = 0.
         endif
      ENDDO

!..Be a bit more conservative with lower cloud fraction in scenario with
!.. well-mixed convective boundary layer below LCL.

      kbot = kts+1
      DO k = kbot, k_m12C
         if ( (theta(k)-theta(k-1)) .gt. 0.010E-3*Dz1d(k)) EXIT
      ENDDO
      kbot = MAX(kts+1, k-2)
      DO k = kts, kbot
         if (cfr1d(k).gt.0.0 .and. cfr1d(k).lt.1.0)                     &
     &              cfr1d(k) = MAX(0.01,0.33*cfr1d(k))
      ENDDO
      DO k = kts,k_tropo
         if (cfr1d(k).gt.0.0) kbot = MIN(k,kbot)
      ENDDO

!..Starting below tropo height, if cloud fraction greater than 1 percent,
!.. compute an approximate total layer depth of cloud, determine a total 
!.. liquid water/ice path (LWP/IWP), then reduce that amount with tuning 
!.. parameter to represent entrainment factor, then divide up LWP/IWP
!.. into delta-Z weighted amounts for individual levels per cloud layer. 

      k_cldb = k_tropo
      in_cloud = .false.
      k = k_tropo
      DO WHILE (.not. in_cloud .AND. k.gt.k_m12C+1)
         k_cldt = 0
         if (cfr1d(k).ge.0.01) then
            in_cloud = .true.
            k_cldt = MAX(k_cldt, k)
         endif
         if (in_cloud) then
            DO k2 = k_cldt-1, k_m12C, -1
               if (cfr1d(k2).lt.0.01 .or. k2.eq.k_m12C) then
                  k_cldb = k2+1
                  goto 87
               endif
            ENDDO
 87         continue
            in_cloud = .false.
         endif
         if ((k_cldt - k_cldb + 1) .ge. 2) then
            call adjust_cloudIce(cfr1d, qi1d, qs1d, qvs1d, T1d, Dz1d,   &
     &                           entrmnt, k_cldb,k_cldt,kts,kte)
            k = k_cldb
         elseif ((k_cldt - k_cldb + 1) .eq. 1) then
            if (cfr1d(k_cldb).gt.0.and.cfr1d(k_cldb).lt.1.)             &
     &        qi1d(k_cldb)=qi1d(k_cldb)+0.05*qvs1d(k_cldb)*cfr1d(k_cldb)
            k = k_cldb
         endif
         k = k - 1
      ENDDO

      k_cldb = k_m12C + 3
      in_cloud = .false.
      k = k_m12C + 2
      DO WHILE (.not. in_cloud .AND. k.gt.kbot)
         k_cldt = 0
         if (cfr1d(k).ge.0.01) then
            in_cloud = .true.
            k_cldt = MAX(k_cldt, k)
         endif
         if (in_cloud) then
            DO k2 = k_cldt-1, kbot, -1
               if (cfr1d(k2).lt.0.01 .or. k2.eq.kbot) then
                  k_cldb = k2+1
                  goto 88
               endif
            ENDDO
 88         continue
            in_cloud = .false.
         endif
         if ((k_cldt - k_cldb + 1) .ge. 2) then
            call adjust_cloudH2O(cfr1d, qc1d, qvs1d, T1d, Dz1d,         &
     &                           entrmnt, k_cldb,k_cldt,kts,kte)
            k = k_cldb
         elseif ((k_cldt - k_cldb + 1) .eq. 1) then
            if (cfr1d(k_cldb).gt.0.and.cfr1d(k_cldb).lt.1.)             &
     &        qc1d(k_cldb)=qc1d(k_cldb)+0.05*qvs1d(k_cldb)*cfr1d(k_cldb)
            k = k_cldb
         endif
         k = k - 1
      ENDDO


      END SUBROUTINE find_cloudLayers

!+---+-----------------------------------------------------------------+

      SUBROUTINE adjust_cloudIce(cfr,qi,qs,qvs,T,dz,entr, k1,k2,kts,kte)
!
      IMPLICIT NONE
!
      INTEGER, INTENT(IN):: k1,k2, kts,kte
      REAL, INTENT(IN):: entr
      REAL, DIMENSION(kts:kte), INTENT(IN):: cfr, qs, qvs, T, dz
      REAL, DIMENSION(kts:kte), INTENT(INOUT):: qi
      REAL:: iwc, max_iwc, tdz, this_iwc, this_dz
      INTEGER:: k

      tdz = 0.
      do k = k1, k2
         tdz = tdz + dz(k)
      enddo
!     max_iwc = ABS(qvs(k2)-qvs(k1))
      max_iwc = MAX(0.0, qvs(k1)-qvs(k2))

      do k = k1, k2
         max_iwc = MAX(1.E-6, max_iwc - (qi(k)+qs(k)))
      enddo
      max_iwc = MIN(1.E-4, max_iwc)

      this_dz = 0.0
      do k = k1, k2
         if (k.eq.k1) then
            this_dz = this_dz + 0.5*dz(k)
         else
            this_dz = this_dz + dz(k)
         endif
         this_iwc = max_iwc*this_dz/tdz
         iwc = MAX(1.E-6, this_iwc*(1.-entr))
         if (cfr(k).gt.0.0.and.cfr(k).lt.1.0.and.T(k).ge.203.16) then
            qi(k) = qi(k) + cfr(k)*cfr(k)*iwc
         endif
      enddo

      END SUBROUTINE adjust_cloudIce

!+---+-----------------------------------------------------------------+

      SUBROUTINE adjust_cloudH2O(cfr, qc, qvs,T,dz,entr, k1,k2,kts,kte)
!
      IMPLICIT NONE
!
      INTEGER, INTENT(IN):: k1,k2, kts,kte
      REAL, INTENT(IN):: entr
      REAL, DIMENSION(kts:kte), INTENT(IN):: cfr, qvs, T, dz
      REAL, DIMENSION(kts:kte), INTENT(INOUT):: qc
      REAL:: lwc, max_lwc, tdz, this_lwc, this_dz
      INTEGER:: k

      tdz = 0.
      do k = k1, k2
         tdz = tdz + dz(k)
      enddo
!     max_lwc = ABS(qvs(k2)-qvs(k1))
      max_lwc = MAX(0.0, qvs(k1)-qvs(k2))
!     print*, ' max_lwc = ', max_lwc, ' over DZ=',tdz

      do k = k1, k2
         max_lwc = MAX(1.E-6, max_lwc - qc(k))
      enddo
      max_lwc = MIN(1.E-4, max_lwc)

      this_dz = 0.0
      do k = k1, k2
         if (k.eq.k1) then
            this_dz = this_dz + 0.5*dz(k)
         else
            this_dz = this_dz + dz(k)
         endif
         this_lwc = max_lwc*this_dz/tdz
         lwc = MAX(1.E-6, this_lwc*(1.-entr))
         if (cfr(k).gt.0.0.and.cfr(k).lt.1.0.and.T(k).ge.258.16) then
            qc(k) = qc(k) + cfr(k)*cfr(k)*lwc
         endif
      enddo

      END SUBROUTINE adjust_cloudH2O

!+---+-----------------------------------------------------------------+

!..Do not alter any grid-explicitly resolved hydrometeors, rather only
!.. the supposed amounts due to the cloud fraction scheme.

      SUBROUTINE adjust_cloudFinal(cfr, qc, qi, Rho,dz, kts,kte)
!
      IMPLICIT NONE
!
      INTEGER, INTENT(IN):: kts,kte
      REAL, DIMENSION(kts:kte), INTENT(IN):: cfr, Rho, dz
      REAL, DIMENSION(kts:kte), INTENT(INOUT):: qc, qi
      REAL:: lwp, iwp, xfac
      INTEGER:: k

      lwp = 0.
      iwp = 0.
      do k = kts, kte
         if (cfr(k).gt.0.0 .and. cfr(k).lt.1.0) then
            lwp = lwp + qc(k)*Rho(k)*dz(k)
            iwp = iwp + qi(k)*Rho(k)*dz(k)
         endif
      enddo

      if (lwp .gt. 1.0) then
         xfac = 1.0/lwp
         do k = kts, kte
            if (cfr(k).gt.0.0 .and. cfr(k).lt.1.0) then
               qc(k) = qc(k)*xfac
            endif
         enddo
      endif

      if (iwp .gt. 1.0) then
         xfac = 1.0/iwp
         do k = kts, kte
            if (cfr(k).gt.0.0 .and. cfr(k).lt.1.0) then
               qi(k) = qi(k)*xfac
            endif
         enddo
      endif

      END SUBROUTINE adjust_cloudFinal

!+---+-----------------------------------------------------------------+

      subroutine cloud_fraction_XuRandall                               &
     &     ( IX, NLAY, plyr, clwf, rhly, qstl,                          & !  ---  inputs
     &       cldtot )                                                   & !  ---  outputs
 
!  ---  inputs:
      integer, intent(in) :: IX, NLAY
      real (kind=kind_phys), dimension(:,:), intent(in) :: plyr, clwf,  &
     &                                                     rhly, qstl  

!  ---  outputs
      real (kind=kind_phys), dimension(:,:), intent(inout) :: cldtot

!  ---  local variables:

       real (kind=kind_phys) :: clwmin, clwm, clwt, onemrh, value,      &
     &       tem1, tem2
       integer :: i, k

!> - Compute layer cloud fraction.

        clwmin = 0.0
        do k = 1, NLAY
        do i = 1, IX
          clwt = 1.0e-6 * (plyr(i,k)*0.001)

          if (clwf(i,k) > clwt) then

            onemrh= max( 1.e-10, 1.0-rhly(i,k) )
            clwm  = clwmin / max( 0.01, plyr(i,k)*0.001 )

            tem1  = min(max(sqrt(sqrt(onemrh*qstl(i,k))),0.0001),1.0)
            tem1  = 2000.0 / tem1

            value = max( min( tem1*(clwf(i,k)-clwm), 50.0 ), 0.0 )
            tem2  = sqrt( sqrt(rhly(i,k)) )

            cldtot(i,k) = max( tem2*(1.0-exp(-value)), 0.0 )
          endif
        enddo
        enddo

      end subroutine cloud_fraction_XuRandall
 
!+---+-----------------------------------------------------------------+
 
      subroutine cloud_fraction_mass_flx_1                              &
     &     ( IX, NLAY, lmfdeep2, xrc3, plyr, clwf, rhly, qstl,          & !  ---  inputs
     &       cldtot )                                                   & !  ---  outputs
 
!  ---  inputs:
      integer, intent(in) :: IX, NLAY
      real (kind=kind_phys), intent(in)                 :: xrc3
      real (kind=kind_phys), dimension(:,:), intent(in) :: plyr, clwf,  &
     &                                                     rhly, qstl  
      logical, intent(in) :: lmfdeep2

!  ---  outputs
      real (kind=kind_phys), dimension(:,:), intent(inout) :: cldtot

!  ---  local variables:

       real (kind=kind_phys) :: clwmin, clwm, clwt, onemrh, value,      &
     &       tem1, tem2
       integer :: i, k

!> - Compute layer cloud fraction.

        clwmin = 0.0
        do k = 1, NLAY
        do i = 1, IX
          clwt = 1.0e-6 * (plyr(i,k)*0.001)
!         clwt = 2.0e-6 * (plyr(i,k)*0.001)

          if (clwf(i,k) > clwt) then
            onemrh= max( 1.e-10, 1.0-rhly(i,k) )
            clwm  = clwmin / max( 0.01, plyr(i,k)*0.001 )
!
            tem1  = min(max((onemrh*qstl(i,k))**0.49,0.0001),1.0)  !jhan
            if (lmfdeep2) then
              tem1  = xrc3 / tem1
            else
              tem1  = 100.0 / tem1
            endif
!
            value = max( min( tem1*(clwf(i,k)-clwm), 50.0 ), 0.0 )
            tem2  = sqrt( sqrt(rhly(i,k)) )

            cldtot(i,k) = max( tem2*(1.0-exp(-value)), 0.0 )
          endif
        enddo
        enddo

      end subroutine cloud_fraction_mass_flx_1
 
!+---+-----------------------------------------------------------------+
 
      subroutine cloud_fraction_mass_flx_2                              &
     &     ( IX, NLAY, lmfdeep2, xrc3, plyr, clwf, rhly, qstl,          & !  ---  inputs
     &       cldtot )                                                   & !  ---  outputs
 
!  ---  inputs:
      integer, intent(in) :: IX, NLAY
      real (kind=kind_phys), intent(in)                 :: xrc3
      real (kind=kind_phys), dimension(:,:), intent(in) :: plyr, clwf,  &
     &                                                     rhly, qstl  
      logical, intent(in) :: lmfdeep2

!  ---  outputs
      real (kind=kind_phys), dimension(:,:), intent(inout) :: cldtot

!  ---  local variables:

       real (kind=kind_phys) :: clwmin, clwm, clwt, onemrh, value,      &
     &       tem1, tem2
       integer :: i, k

!> - Compute layer cloud fraction.

        clwmin = 0.0
        do k = 1, NLAY-1
        do i = 1, IX
          clwt = 1.0e-10 * (plyr(i,k)*0.001)

          if (clwf(i,k) > clwt) then
            if(rhly(i,k) > 0.99) then
              cldtot(i,k) = 1.
            else
              onemrh= max( 1.e-10, 1.0-rhly(i,k) )
              clwm  = clwmin / max( 0.01, plyr(i,k)*0.001 )

              tem1  = min(max((onemrh*qstl(i,k))**0.49,0.0001),1.0)  !jhan
              if (lmfdeep2) then
                tem1  = xrc3 / tem1
              else
                tem1  = 100.0 / tem1
              endif

              value = max( min( tem1*(clwf(i,k)-clwm), 50.0 ), 0.0 )
              tem2  = sqrt( sqrt(rhly(i,k)) )

              cldtot(i,k) = max( tem2*(1.0-exp(-value)), 0.0 )
            endif
          else
            cldtot(i,k) = 0.0
          endif
        enddo
        enddo

      end subroutine cloud_fraction_mass_flx_2 
!........................................!
      end module module_radiation_clouds
!! @}
!========================================!
