PROGRAM obsop_drifters
  
  USE common ! use r_size 
  USE common_obs_oceanmodel ! use get_nobs   
  USE common_oceanmodel
  USE letkf_drifters_local, ONLY : obs_local  !(DRIFTERS) NOTE: this is a slightly modified version of letkf_local.f90
  USE letkf_drifters_tools
  USE params_letkf
  USE params_model
  USE params_obs
  USE vars_model

  IMPLICIT NONE
  CHARACTER(slen) :: obsinfile = 'obsin_drifters.dat'	!IN (default) observation data of drifters
  CHARACTER(slen) :: guesfile = 'gues'	!IN data from model space in folder "DRIFTERS"
  CHARACTER(slen) :: obsoutfile = 'obsout_drifters.dat'	!OUT (default) datafile to be passed to letkf
  
  REAL(r_size), ALLOCATABLE :: elem(:)	!elem(:)
  REAL(r_size), ALLOCATABLE :: rlon(:)
  REAL(r_size), ALLOCATABLE :: rlat(:)
  REAL(r_size), ALLOCATABLE :: rlev(:)
  INTEGER     , ALLOCATABLE :: obid(:)	! odat
  REAL(r_size), ALLOCATABLE :: oerr(:)
  REAL(r_size), ALLOCATABLE :: ohx(:)	! Model forecast transformed to observation space: H(xb)
  INTEGER     , ALLOCATABLE :: oqc(:)	! quality control, necessary for drifters?
  REAL(r_size), ALLOCATABLE :: otime(:) ! time
  REAL(r_sngl), ALLOCATABLE :: v4d_all(:,:,:)
  !INTEGER :: nobs  ! total number of drifters observation
  REAL(r_size) :: ri, rj, rk
  INTEGER :: n, nnobs

  !-----------------------------------------------------------------------------
  ! Initialize the common_mom4 module, and process command line options
  !-----------------------------------------------------------------------------
   CALL set_common_oceanmodel
  !CALL set_common_drifters 
  !CALL process_command_line ! ??, what does this for should I write the subroutine

  !-----------------------------------------------------------------------------
  ! Read observations from file
  !-----------------------------------------------------------------------------
  CALL get_nobs(obsinfile,7,nnobs) !Later, need to add time.
  
  ALLOCATE(  elem(nnobs)  )
  ALLOCATE(  rlon(nnobs)  )
  ALLOCATE(  rlat(nnobs)  )
  ALLOCATE(  rlev(nnobs)  )
  ALLOCATE(  obid(nnobs)  ) ! odat
  ALLOCATE(  oerr(nnobs)  ) ! 
  ALLOCATE(   ohx(nnobs)  ) ! Model forecast transformed to observation space: H(xb)
  ALLOCATE(   oqc(nnobs)  )  
  ALLOCATE(  otime(nnobs) ) ! otime
  print *, 'Finish get_nobs and start read_obs2_drifters.'
  CALL read_obs2_drifters(obsinfile,nnobs,elem,rlon,rlat,rlev,obid,oerr,otime)
  print *, 'Start read_drifters'
  !-----------------------------------------------------------------------------
  ! Read model forecast for this member
  !-----------------------------------------------------------------------------
  CALL read_dimension(trim(guesfile),num_drifters,num_times)
  ALLOCATE(v4d_all(num_drifters,num_times,nv4d))
  CALL read_drifters(trim(guesfile),v4d_all) ! read_drifters is in letkf_drifters_tools.f90, read data from model space.
  ! From this step, we obtain from models, num_drifters, num_times, drifter_ids, drifter_times. 
  print *, 'Finish read_drifters'
  !-----------------------------------------------------------------------------
  ! Cycle through all observations
  !-----------------------------------------------------------------------------
  ohx=0.0d0
  DO n=1,nnobs
    !---------------------------------------------------------------------------
    ! Convert the physical coordinate to model grid coordinate (note: real, not integer)
    !---------------------------------------------------------------------------
    !print *, elem(n),obid(n),otime(n),rlon(n),rlat(n),rlev(n)
    !print *, 'Start drift2ijk'
    !print *, 'otime(n)=', otime(n)
    CALL drift2ijk(elem(n),obid(n),otime(n),rlon(n),rlat(n),rlev(n),ri,rj,rk) 
    !print *, 'Finish drift2ijk'
    print *, 'rj = ', rj
    print *, obid(n), '=', ri
    print *, 'rk = ', rk
    ! ri: drifter id index
    ! rj: time idex for interpolation
    ! rk: var (x,y,x) index if elem == iv4d_x,y,z, then rk = 1,2,3 so on
    !print *, elem(n),obid(n),otime(n),rlon(n),rlat(n),rlev(n),ri,rj,rk
    !---------------------------------------------------------------------------
    ! Filter in the tripolar region until localization is examined in the arctic !(ISSUE)
    !---------------------------------------------------------------------------

    !---------------------------------------------------------------------------
    ! Check the observation against boundaries
    !---------------------------------------------------------------------------

    !---------------------------------------------------------------------------
    ! observation operator (computes H(x)) for specified member
    !---------------------------------------------------------------------------
    !print *, 'Start Trans_DtoY'
    CALL Trans_DtoY(elem(n),ri,rj,rk,v4d_all,ohx(n))
    oqc(n)=1

    !---------------------------------------------------------------------------
    ! Filter out observations that are out of range for the grid
    !--------------------------------------------------------------------------
    !print *, "The boundary is lon(1)=",lon(1),"lon(nlon)=",lon(nlon)
    !print *, "The boundary is lat(1)=",lat(1),"lat(nlat)=",lat(nlat) 
    if ( rlon(n) < lon(1) .OR. rlon(n) > lon(nlon) ) then
      oqc(n)=0
      print *, 'remove number obs n = ', n
      print *, obid(n),rlon(n),rlat(n)
    else
      if ( rlat(n) < lat(1) .OR. rlat(n)>lat(nlat) ) then
        oqc(n)=0
        print *, 'remove number obs n = ', n
        print *, obid(n),rlon(n),rlat(n)
      end if
    end if

    !print *, "n=",n,"ohx=",ohx(n)
  enddo ! end do n=1,nobs

  !-----------------------------------------------------------------------------
  ! Print out the counts of observations removed for various reasons
  !-----------------------------------------------------------------------------

  !-----------------------------------------------------------------------------
  ! Write the observations and their associated innovations to file
  !-----------------------------------------------------------------------------
  print *, 'Start write_obs2_drifters'
  !print *, 'otime=', otime
  CALL write_obs2_drifters(obsoutfile,nnobs,elem,rlon,rlat,rlev,obid,oerr,ohx,oqc,otime)
  print *, 'Finish write_obs2_drifters'
 CONTAINS
!SUBROUTINE process_command_line
!===============================================================================
! Process command line arguments 
!===============================================================================
!END SUBROUTINE process_command_line
END PROGRAM obsop_drifters
