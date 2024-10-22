program pressure_pulse_GAUSSIAN_vr



    ! This is the SWL pulse code



    implicit none
    integer, parameter            :: n_order = 4, no_press = 1, tf = 800000000!!80001 added two zeros!
    !n_order: order of finite different scheme used in calculating normals etc. (must be even)
    !no_press: counter used in calculating internal fluid pressures (not used in this case)
    !tf: total number of time steps
    double precision, parameter   :: Pb = 0d0, rho = 1d0,&
        delt = 0d0, Pref = 1d0,&!500d0,&!5280d0,&
        lam = 0d0, eps = 100d0,&!100d0 !Strength parameter
        Wn = 89.4d0, &          ! -27.72d0
        Us = 1d0, Pa = 2000000d0, PP0 = 101000,&!MACH = 0.0214d0     ! 89.11d0
        Rhow = 998d0, R0 = 1d-6, freq = 2000000d0,&
        ff = 1000000d0, mush = 0.006d0, shw = 0.001d0 !0.001d0 !3d-3

    !Pinf: pressure at infinity
    !Pb: bubble pressure
    !rho: fluid density (non-dimensionalisation has meant that this isn't used)
    double precision, allocatable :: r(:), z(:), phi(:), G(:, :), H(:), HP(:), &
        ar(:), br(:),cr(:), dr(:), er(:),&
        az(:), bz(:), cz(:), dz(:), ez(:),&
        const(:), r_new(:),&
        z_new(:), rem_new(:), phi_new(:), nr(:),&
        nz(:), A1(:), A2(:),&
        radius(:), tang_vel(:),&
        sr(:), sz(:), resultant_vel(:),&
        s(:), ars(:), brs(:),crs(:), drs(:), ers(:), &
        azs(:), bzs(:), czs(:), dzs(:), ezs(:),&
        r_new_arc(:), z_new_arc(:),&
        r_curvature(:),&
        curvature(:), viscous_term(:),&
        dphi2_ds2(:), r_smooth(:), z_smooth(:),&
        phi_smooth(:), z_image(:),&
        aphi(:), bphi(:), cphi(:), dpphi(:), ephi(:),&
        r_graph(:), z_graph(:),&
        r_graph_aft(:), z_graph_aft(:),&
        r_graphop(:), z_graphop(:),&
        dphi2_dsdn(:), extra_stress(:),&
        dphi2_dn2(:), dphi2_dsdn_smooth(:),&
        dphi2_ds2_smooth(:),&
        s_new(:), r_old(:), z_old(:), phi_old(:),&
        k1_r(:), k2_r(:),  k1_z(:), k2_z(:),&
        k1_phi(:), k2_phi(:),k3_phi(:), k4_phi(:),&
        k3_r(:), k4_r(:), k3_z(:), k4_z(:),&
        extra_stress_old(:),&
        pressure_surf(:), pressure_surf_2(:),&
        vel_x_surf(:), vel_y_surf(:),&
        aTs(:), bTs(:), cTs(:), dTs(:), eTs(:),&
        ex_str_new_arc(:), ex_str_smooth(:),&
        abs_ex_str(:), t_step_den(:),&
        G2(:,:), H2(:), A12(:), B(:), const2(:), HPnew(:),&
        G3(:), H3(:),&
        r_normal(:), z_normal(:), phi_normal(:),&
        z_normal_image(:),&
        extra_stress_new(:),&
        ds(:),&
        HP2(:), adphidn(:), bdphidn(:), cdphidn(:),&
        ddphidn(:), edphidn(:),&
        ar_s(:), br_s(:), cr_s(:), dr_s(:), er_s(:),&
        az_s(:), bz_s(:), cz_s(:),&
        dz_s(:), ez_s(:), s_s(:),&
        aphi_s(:), bphi_s(:), cphi_s(:), dphi_s(:), ephi_s(:),& !Vortex ring variables:
        arcint(:), vpot(:), rem_pot(:), aphir(:),&
        bphir(:), cphir(:), dphir(:), ephir(:),&
        HP_rem(:), tang_rem(:),&
        HP_rem_new(:), drem2_dsdn(:),&
        drem2_ds2(:), drem2_dn2(:), resultant_rem(:),&
        u_vortex(:), w_vortex(:), tempr(:), k1_rem(:),&
        k2_rem(:), k3_rem(:), k4_rem(:), &
        rem_pot_old(:), rem_pot_new(:),low_r_orig(:),&
        low_z_orig(:), low_r(:), low_z(:),&
        G2_rem(:,:), HP2_rem(:), tempy(:), IPIV(:),&
        rem_pot_smooth(:), phi_temp(:), phi_dr(:), phi_dz(:),&
        aphi_temp(:), bphi_temp(:), cphi_temp(:), dphi_temp(:),&
        ephi_temp(:),phiHP(:),&
        aphihp(:), bphihp(:), cphihp(:), dphihp(:), ephihp(:),&
        aHP(:), bHP(:),&
        cHP(:), dHP(:), eHP(:), remspline(:,:), s_int(:,:),&
        drem(:,:), d2rem(:,:), HP_new(:), minz(:), ztemp(:),&
        rtester(:), ztester(:), Pinf(:),&
        vpot_new(:), tempp(:), vrphi(:),&
        rem2(:), pyth(:),&
        xts(:,:), xtempsp(:,:), resultant_test(:), temp(:),&
        absvel(:), vel_x(:), vel_y(:), r_internal(:), z_internal(:),&
        phi_int(:), size_int(:), phi_int_old(:), presh(:),&
        rem_int(:), vort_int(:), jet_approx(:), gi(:), mindist(:,:),&
        mind(:), loc(:), rr_int(:), zz_int(:), devi(:), k1_t(:),&
        k2_t(:), k3_t(:), k4_t(:), test1(:), test2(:), test3(:), test4(:),&
        fff(:,:), ffn(:,:), aff(:,:), bff(:,:), cff(:,:), dff(:,:), eff(:,:),&
        afn(:,:), bfn(:,:), cfn(:,:), dfn(:,:), efn(:,:), row(:), row2(:), ztime(:), tnode(:),&
        preshwall(:),&
        r_wall(:), z_wall(:), phi_int2(:), phi_int_old2(:), rem_int2(:), vel_x2(:),&
        vel_y2(:), vort_int2(:), Pinf2(:), PBB(:)


    double precision              :: rad, length,&
        pi, &!dphi,&
        dt, time, thit,&
        Gimage_int1, Gimage_int2, Himage_int1, Himage_int2,&
        av_norm_vel,&
        jet_hit,&
        dh, alpha,&
        height,&
        mu, lambda,&
        phi_0,&
        dt_max, deltaT, deltaPhi,&
        dt_cut,&
        minimumR,&
        centroid, centroidr,&
        V0, jet_velocity,&
        vri, vzi, dphi,&
        eq_rad, jett, EE,&
        vol, vol2, total_energy, E1, E2, E3, E4,&
        pulsetop, pulsebot, pulseneg, inrad, E1_app, zmin, pulsechange,&
        rmin, hh, minrr, minzz, maxrr, maxzz, Rey, Deb, intern, tpulse,&
        tstar, AP, indist, minrdist, dtt, pulsetop2, pulsebot2, pulsechange2, AP2, tstar2,&
        AP0, tstar0, omeg, pmid, pmid2, Ws, pb0, pt0, Webinv, pb20, pt20, pmid20, chi, ppc

    integer                       :: i, jj, l, t, ll, k, wall_switch, p, teller,&
        np, torus_switch, npnew, t1, t11, t12, t2, t2a, t3, t4, t1a, t1b,&
        smoothing, N_trap, N_int, tteller2, teller3, counter,&
        no_int, q, j, INOUTT(441), viscel, singswitch, ccc, ddd, no_wall, preshswitch


    ! character(len=5)              :: visc_name, lamb_name, height_name, t_name
    ! character(len=3)              :: no_elements



    np = 36               !! The number of segments making up the bubble surface
                          !! Hence (np + 1) is the number of nodes
    N_trap = 20          !! Nodes for trapezoidal rule
    N_int = 20            !! Number of points where spline functions are evaluated
    hh = 0.1d0
    q = 21   ! 2/h + 1
    no_int = 6 !41 !21 !441  ! q*q
    no_wall = 3

    allocate(r(np + 1), z(np + 1),&
        phi(np + 1),&
        G(np + 1, np + 1), H(np + 1), HP(np + 1), &
        ar(np + 1), br(np + 1),cr(np + 1), dr(np + 1), er(np + 1),&
        az(np + 1), bz(np + 1), cz(np + 1), dz(np+1), ez(np+1),&
        const(np + 1), r_new(np + 1),&
        z_new(np + 1), rem_new(np + 1), phi_new(np + 1), nr(np + 1),&
        nz(np + 1), A1(np + 1), A2(np + 1),&
        radius(np + 1), tang_vel(np + 1),&
        sr(np + 1), sz(np + 1), resultant_vel(np + 1),&
        s(np + 1), ars(np + 1), brs(np + 1),crs(np + 1), &
        drs(np + 1), ers(np + 1),&
        azs(np + 1), bzs(np + 1), czs(np + 1),&
        dzs(np + 1), ezs(np + 1),&
        r_new_arc(np + 1), z_new_arc(np + 1),&
        r_curvature(np + 1),&
        curvature(np + 1), viscous_term(np + 1),&
        dphi2_ds2(np + 1), r_smooth(np + 1), z_smooth(np + 1),&
        rem_pot_smooth(np + 1),&
        phi_smooth(np + 1), z_image(np + 1),&
        aphi(np + 1), bphi(np + 1), cphi(np + 1),&
        dpphi(np + 1), ephi(np + 1),&
        r_graph(2*np + 1), z_graph(2*np + 1),&
        r_graph_aft(np + 1), z_graph_aft(np + 1),&
        r_graphop(np+1), z_graphop(np+1),&
        dphi2_dsdn(np + 1), extra_stress(np + 1),&
        dphi2_dn2(np + 1), dphi2_dsdn_smooth(np + 1),&
        dphi2_ds2_smooth(np + 1),&
        s_new(np + 1), r_old(np + 1), z_old(np + 1), phi_old(np + 1),&
        k1_r(np + 1), k2_r(np + 1),  k1_z(np + 1), k2_z(np + 1),&
        k1_phi(np + 1), k2_phi(np + 1),k3_phi(np + 1), k4_phi(np + 1),&
        k3_r(np + 1), k4_r(np + 1), k3_z(np + 1), k4_z(np + 1),&
        extra_stress_old(np + 1),&
        pressure_surf(np + 1), pressure_surf_2(2*np + 1),&
        vel_x_surf(np + 1), vel_y_surf(np + 1),&
        aTs(np + 1), bTs(np + 1), cTs(np + 1),&
        dTs(np + 1), eTs(np + 1),&
        ex_str_new_arc(np + 1), ex_str_smooth(np + 1),&
        abs_ex_str(np + 1), t_step_den(np + 1),&
        G2(np - 1, np + 1), H2(np-1), B(np-1), A12(np-1),&
        const2(np-1), HPnew(np+1),&
        extra_stress_new(np + 1), ds(np),&
        HP2(np + 1), adphidn(np + 1), bdphidn(np + 1), cdphidn(np + 1),&
        ddphidn(np + 1), edphidn(np + 1),&
        ar_s(np), br_s(np), cr_s(np), dr_s(np), er_s(np),&
        az_s(np), bz_s(np), cz_s(np), dz_s(np), ez_s(np), s_s(np),&
        aphi_s(np), bphi_s(np), cphi_s(np),&
        dphi_s(np), ephi_s(np),&!Vortex ring variables:
        arcint(np + 1), vpot(np + 1), rem_pot(np + 1),&
        aphir(np + 1), bphir(np + 1), cphir(np + 1),&
        dphir(np + 1), ephir(np + 1),&
        HP_rem(np + 1), tang_rem(np + 1),&
        HP_rem_new(np + 1), drem2_dsdn(np + 1),&
        drem2_ds2(np + 1), drem2_dn2(np + 1),&
        resultant_rem(np + 1), u_vortex(np + 1),&
        w_vortex(np + 1), tempr(np + 1), k1_rem(np + 1),&
        k2_rem(np + 1), k3_rem(np + 1), k4_rem(np + 1),&
        rem_pot_old(np + 1), rem_pot_new(np + 1),&
        low_r_orig(np + 1), low_z_orig(np + 1),&
        low_r(np + 1), low_z(np + 1),&
        G2_rem(np,np-1), HP2_rem(np + 1), tempy(np + 1),&
        IPIV(np + 1), phi_temp(np + 1), phi_dr(np + 1),&
        phi_dz(np + 1), aphi_temp(np + 1),&
        bphi_temp(np + 1), cphi_temp(np + 1), &
        dphi_temp(np + 1), ephi_temp(np + 1),&
        phiHP(np + 1), aphihp(np + 1), bphihp(np + 1),&
        cphihp(np + 1), dphihp(np + 1), ephihp(np + 1),&
        aHP(np+1), bHP(np+1), cHP(np+1),&
        dHP(np+1), eHP(np+1),remspline(np,N_int+1),&
        s_int(np,N_int+1), drem(np,N_int+1),&
        d2rem(np,N_int+1), HP_new(np+1), minz(np+1),&
        ztemp(np+1), rtester(np+1), ztester(np+1),&
        Pinf(np + 1),&
        vpot_new(np + 1), tempp(np+1), vrphi(np+1),&
        rem2(np + 1), pyth(np + 1), xts(np+1,N_trap+1),&
        xtempsp(np+1,N_trap+1), resultant_test(np+1),&
        temp(np + 1), absvel(np+1), vel_x(no_int), vel_y(no_int),&
        r_internal(no_int+1), z_internal(no_int+1),&
        phi_int(no_int), size_int(no_int), phi_int_old(no_int),&
        presh(no_int), rem_int(no_int), vort_int(no_int),&
        jet_approx(no_int), gi(no_int),&
        mindist( (N_int+1)*(N_int+1),np+1 ),&
        mind( (N_int+1)*(N_int+1) ), rr_int( (N_int+1)*(N_int+1) ),&
        zz_int( (N_int+1)*(N_int+1) ), loc((N_int+1)*(N_int+1)), devi(np+1),&
        k1_t(np+1), k2_t(np+1), k3_t(np+1), k4_t(np+1),&
        test1(np+1), test2(np+1), test3(np+1), test4(np+1), fff(np+1,np+1),&
        ffn(np+1,np+1), aff(np+1,np+1), bff(np+1,np+1), cff(np+1,np+1), dff(np+1,np+1),&
        eff(np+1,np+1), afn(np+1,np+1), bfn(np+1,np+1), cfn(np+1,np+1), dfn(np+1,np+1),&
        efn(np+1,np+1), row(np+1), row2(np+1), ztime(np+1), tnode(np+1), preshwall(no_wall),&
        r_wall(no_wall), z_wall(no_wall), phi_int2(no_wall), phi_int_old2(no_wall),&
        rem_int2(no_wall), vel_x2(no_wall),&
        vel_y2(no_wall), vort_int2(no_wall), Pinf2(np+1), PBB(np+1)   )


    allocate( phi_normal(np+1),G3(np+1), H3(np+1), r_normal(np+1),&
        z_normal(np+1), z_normal_image(np+1) )



    !*** Initial potential on bubble surface (from spherical inviscid Rayleigh Eqn.)
    phi_0 = 0d0!-0.1d0*((2d0/3d0)*((1d0/0.1d0)**3 - 1d0))**0.5d0

    height = 5d0 ! Initial height of bubble centre from wall

    mu = 1d0 ! (1/RE) viscosity
    lambda = 10d0!0.1d0 ! (Equal to Deborah number) relaxation time
    EE = 0d0
    rad = 1d0!0.3804d0!0.1651d0!0.1d0! ! Initial radius
    if(lambda.eq.0d0)then
       if(mu.eq.0d0)then
          viscel = 0     ! = 0 if inviscid, = 1 if viscosity, = 2 if viscoelastic
       elseif(mu.ne.0d0)then
          viscel = 1
       endif
    else
       viscel = 2
    endif

    ! Pulse width
    Ws = 4d0*10.0599d0/(R0*freq)

    pi = 4d0*datan(1d0) !pi, the mathematical constant
    omeg = 2d0*pi*freq

    ppc = 998*(R0**2d0)*( (2d0*pi*freq)**2d0 )

    Webinv = 0d0!2d0*0.051d0/( ppc*R0 )
    chi = 2d0*0.5d0/( ppc*R0 )


    singswitch = 0

    Rey = 10d0
    Deb = 0.1d0


    wall_switch = 1 !wall_switch=1: rigid wall present
                     !           =0: rigid wall absent
    torus_switch = 0 ! becomes 1 when jet impact happens

    preshswitch = 1  ! = 1 if we want pulse on, = 0 if not

    jj = 1 !spare counter




    dh = 1d-2 ! distance between internal points (used in calculating internal fluid velocites only)
    dt_max = 0.01d0! maximum time step (upper bound of variable time step)
    dt_cut = 1d-6          ! time step after impact

    intern = 1    ! 1 if want to plot internal quantities, i.e. pressure field
    time = 0d0  ! Initial physical time

    pressure_surf = 0d0 !pressure on surface
    extra_stress = 0d0 !norm-norm component of extra stress (Tnn)
    extra_stress_old = 0d0 !prev. value of extra stress

    teller = 0             ! counts the number of iterations after torus formation
    teller3 = 0            ! becomes 2 when bub reconnected after toroidal
    alpha = 1d0/16d0       ! degree of smoothing
    smoothing = 3
    counter = 0
    ccc = 0
    ddd = 0
    omeg = 2d0*pi*freq  ! Frequency of pulses



    !*** Opens file where bubble surface data is written***
    !*** Change directory/filename appropriately ***

    open(999,file='bub_surf_before.dat')        ! file that will contain the bubble surface data
    open(1000,file='bub_surf_before2.dat')
    open(1001,file='bub_surf_before3.dat')
    open(998,file='busu_times_before.dat')
    open(888,file='jet_vel.dat')               ! file to which jet velocity is written
    open(333,file='volume.dat')                ! file to which volume is written
    open(444,file='volume_after.dat')          ! contains only the volume data after torus formation
    open(555,file='jet_velocity_after.dat')    ! contains only the jet velocity data after torus formation
    open(9999,file='bub_surf_after.dat')       !bubble surface data after transition
    open(99991,file='bub_surf_after2.dat')
    open(9998,file='busu_times_after.dat')
    open(99998,file='busu_times_vortexsecond.dat')
    open(711,file='pressurepulses.dat')
    open(997,file='bub_surf_reconnected.dat')
    open(123,file='norm_tang_vels.dat')
    open(666,file='rad_vs_time.dat')
    open(200,file='ENERGYTERMS.dat')
    open(300,file='ENERGY.dat')
    open(201,file='ENERGYTERMS_AFTER.dat')
    open(301,file='Remsplines.dat')
    open(401,file='Deriv_Remsplines.dat')
    open(501,file='2Deriv2_Remsplines.dat')
    open(456,file='atransitiontimes.dat')
    open(567,file='bubsurf_2ndvr.dat')
    open(234,file='field_variables.dat')
    open(383,file='centroid_eqrad.dat')
    open(484,file='pulse_times.dat')
    open(101010,file='transition times.dat')



    do 100  t = 0, tf !! Loop over time: tf is max number of time steps

        do 101 ll  = 1, 5  !!***ll is a counter for the intermediate Runge-Kutta times steps***
              !!In the ll=5 stage, we do not update in time, just find un-distributed stress
              !!It is then redistributed, at ll=1 in the next time step (which is at the same physical time as ll=5 previous)

              !! Initialise variables

            Gimage_int1 = 0d0 !Bubble image integration variable
            Gimage_int2 = 0d0 !Bubble image integration variable
            Himage_int1 = 0d0 !Bubble image integration variable
            Himage_int2 = 0d0 !Bubble image integration variable
            phi_smooth = 0d0 !Smoothed potential
            tang_vel = 0d0 !tangential velocity
            dphi2_ds2 = 0d0 !second tangential derivative of phi
            HP = 0d0 !normal velocity
            const = 0d0 !constant c(p) from boundary integral eqn.
            ar = 0d0 !
            br = 0d0 ! r spline coefficients
            cr = 0d0 !
            dr = 0d0
            er = 0d0
            az = 0d0 !
            bz = 0d0 ! z spline coefficients
            cz = 0d0 !
            dz = 0d0
            ez = 0d0
            ars = 0d0 !
            brs = 0d0 ! r spline coeff. parametrised wrt arclength
            crs = 0d0 !
            drs = 0d0
            ers = 0d0
            azs = 0d0 !
            bzs = 0d0 ! z spline coeff. parametrised wrt arclength
            czs = 0d0 !
            dzs = 0d0
            ezs = 0d0
            aTs = 0d0 !
            bTs = 0d0 ! extra stress spline coeff. parametrised wrt arclength
            cTs = 0d0 !
            dTs = 0d0
            eTs = 0d0
            aphi = 0d0 !
            bphi = 0d0 ! phi spline coeff. parametrised wrt arclength
            cphi = 0d0 !
            dpphi = 0d0
            ephi = 0d0
            aphir = 0d0
            bphir = 0d0
            cphir = 0d0
            dphir = 0d0
            ephir = 0d0
            nr = 0d0 ! normal vector component in r direction
            nz = 0d0 ! normal vector component in z direction
            s = 0d0 ! arclength: s(np+1)=total arclength
            curvature = 0d0 ! In-plane curvature
            viscous_term = 0d0 !
            H = 0d0 ! RHS of linear system, (np+1) array
            G = 0d0 ! LHS of linear system, (np+1)x(np+1) array
            A1 = 0d0 ! useful array
            s_new = 0d0 ! new arclength
            A2 = 0d0 ! useful array



            do l = 1, (np + 1)
                ! Define initial bubble (and image) surface (1/2 circle)
                if((t.eq.0).and.(ll.eq.1))then
                    r(l) = rad*cos(pi/2d0 - (l - 1d0)*pi/(np))
                    z(l) = rad*sin(pi/2d0 - (l - 1d0)*pi/(np)) + height
                    z_image(l) = -z(l) !Define image bubble surface
                    phi(l) = phi_0
                    extra_stress(l) = 0d0
                   ! HP(l) = -28.1d0!-46.5d0
                   ! phi(l) = rad*HP(l)
                else
                    !Else update surface from previous time step
                    r(l) = r_new(l)
                    z(l) = z_new(l)
                    z_image(l) = -z(l) !Define new image bubble surface
                    !extra_stress(l) = extra_stress_new(l)
                    if(torus_switch.eq.0)then
                    phi(l) = phi_new(l)
                  ! phi(l) = 0d0
                    else
                    rem_pot(l) = rem_new(l)
                    endif

                end if

            enddo

            if(t.eq.0)then
                inrad = ( z(1) - z(np+1) )/2d0! Initial radius
            endif


            if(teller3.eq.2)then
                counter = counter + 1
            endif
            if(time.gt.60d0)then
                write(*,*) 'end time'
                stop
            endif



            !***********************************************************************************
            !***********************************************************************************
            ! Find new value of phi

           if(torus_switch.eq.1)then

                vpot = 0d0
                arcint = 0d0

                CALL vortpot_n1(np,N_trap,deltaPhi,r,z,vri,vzi,vpot(1))


                CALL arcint_calc(np,N_trap,r,z,vri,vzi,deltaPhi,arcint, u_vortex, w_vortex)


                DO k = 2,(np+1)
                    vpot(k) = vpot(k-1) + arcint(k)  !vpot is potential of vortex ring.
                ENDDO

                DO k= 1,(np+1)
                    phi(k) = rem_pot(k) + vpot(k)
                ENDDO




                if(teller.gt.1)then



                !write(*,*) 'teller', teller
                call iterative_arclength_calc(r, z, ar, br, cr, dr, er, az, bz, cz, dz, ez,&
                    s, length, np, torus_switch)


                CALL vrupdate(r,z,phi,rem_pot,vpot,np,vri,vzi,&
                    N_trap, N_int, deltaPhi,&
                    u_vortex, w_vortex, s, time)

                endif

            endif


            !***********************************************************************************
            !***********************************************************************************
            ! Check to see if vortex ring needs to be relocated (toroidal only)

            if((torus_switch.eq.1).and.(teller.gt.1))then

                !write(*,*) 'teller', teller
                call iterative_arclength_calc(r, z, ar, br, cr, dr, er, az, bz, cz, dz, ez,&
                    s, length, np, torus_switch)

                CALL vrupdate(r,z,phi,rem_pot,vpot,np,vri,vzi,&
                    N_trap, N_int, deltaPhi,&
                    u_vortex, w_vortex, s, time)

!write(*,*) '2', phi

            endif


            !************************************************************************************
            !************************************************************************************
            ! Plot bubble surface every t1 steps for singly-connected 1, t2 steps for vr 1, t3 steps
            ! for singly-connected 2, t4 steps for vr 2


            t1 = 450
            t1a = 60
            t1b = 1200
            t2 = 50
            t2a = 500
            t3 = 100
            t4 = 500



  !  first singly-connected phase
  if(teller3.eq.0)then
  if(torus_switch.eq.0)then
    if((ll.eq.1).and.(mod(t,t1).eq.0))then

        call reflect_surface(r_graph, z_graph, r, z, np)

        write(998,*) 'VARIABLES = "r", "z"'
        write(998,*) 'ZONE T="time:',time,'",I=',(np + 1),',J=',1,',F=POINT'
        write(998,*) time
     !   write(*,*) 'time', time

        do i = 1, (2*np + 1) !! Write position of bubble surface to file 999
            write(999,*) r_graph(i), z_graph(i)
        enddo


    endif

    if((ll.eq.1).and.(mod(t,t1a).eq.0))then

        call reflect_surface(r_graph, z_graph, r, z, np)

        do i = 1, (2*np + 1) !! Write position of bubble surface to file 999
            write(1000,*) r_graph(i), z_graph(i)
        enddo


    endif



    if((ll.eq.1).and.(mod(t,t1b).eq.0))then

        call reflect_surface(r_graph, z_graph, r, z, np)

        do i = 1, (2*np + 1) !! Write position of bubble surface to file 999
            write(1001,*) r_graph(i), z_graph(i)
        enddo


    endif

endif
endif

    ! first vr phase
    if((ll.eq.1).and.(torus_switch.eq.1).and.(teller3.eq.1).and.(mod(teller,t2).eq.0))then
        call reflect_surface_torus(r_graph_aft, z_graph_aft, r_graphop, z_graphop, r, z,&
            np)

        write(9998,*) 'VARIABLES = "r", "z"'
        write(9998,*) 'ZONE T="time:',time,'",I=',(np+1),',J=',1,',F=POINT'

        do i = 1, (np + 1) !! Write position of bubble surface to file 999
            write(9999,*) r_graph_aft(i), z_graph_aft(i)
        enddo
        do i = 1, (np + 1)
            write(9999,*) r_graphop(i), z_graphop(i)
        enddo


    endif

    if((ll.eq.1).and.(torus_switch.eq.1).and.(teller3.eq.1).and.(mod(teller,t2a).eq.0))then
        call reflect_surface_torus(r_graph_aft, z_graph_aft, r_graphop, z_graphop, r, z,&
            np)


        do i = 1, (np + 1) !! Write position of bubble surface to file 999
            write(99991,*) r_graph_aft(i), z_graph_aft(i)
        enddo
        do i = 1, (np + 1)
            write(99991,*) r_graphop(i), z_graphop(i)
        enddo


    endif

    ! second singly connected phase
    if(teller3.eq.2)then
    if((ll.eq.1).and.(torus_switch.eq.0).and.(mod(t,t3).eq.0))then

        call reflect_surface(r_graph, z_graph, r, z, np)

        do i = 1, (2*np + 1) !! Write position of bubble surface to file 999
            write(997,*) r_graph(i), z_graph(i)
        enddo


    endif
    endif



    ! second vbr phase
    if((ll.eq.1).and.(torus_switch.eq.1).and.(teller3.eq.3).and.(mod(teller,t4).eq.0))then
        call reflect_surface_torus(r_graph_aft, z_graph_aft, r_graphop, z_graphop, r, z,&
            np)


        do i = 1, (np + 1) !! Write position of bubble surface to file 999
            write(567,*) r_graph_aft(i), z_graph_aft(i)
        enddo
        do i = 1, (np + 1)
            write(567,*) r_graphop(i), z_graphop(i)
        enddo


    endif


    if((ll.eq.1).and.(torus_switch.eq.0).and.(mod(t,50).eq.0))then
        write(711,*) time, pulsebot, pulsetop
    endif


         !  CALL plot_surface(np, r, z, torus_switch, ll, t, t1, t1a, t1b, t2, t2a, t3, t4,&
          !      teller, teller3, pulsebot, pulsetop, time)


            !************************************************************************************
            !************************************************************************************
            ! Smoothing of nodes and variables

             CALL smoothing_var(np, r, z, phi, rem_pot, vpot, ll, t, torus_switch,&
                smoothing, teller, counter, alpha, deltaPhi, N_trap,&
                vri, vzi, N_int, u_vortex, w_vortex, extra_stress)

            if(torus_switch.eq.1)then

                vpot = 0d0
                arcint = 0d0

                CALL vortpot_n1(np,N_trap,deltaPhi,r,z,vri,vzi,vpot(1))


                CALL arcint_calc(np,N_trap,r,z,vri,vzi,deltaPhi,arcint, u_vortex, w_vortex)


                DO k = 2,(np+1)
                    vpot(k) = vpot(k-1) + arcint(k)  !vpot is potential of vortex ring.
                ENDDO

                DO k= 1,(np+1)
                 !   rem_pot(k) = phi(k) - vpot(k)
                  !  phi(k) = rem_pot(k) + vpot(k)
                ENDDO

            endif

            !*** These subroutines calculate the arclength and spline coefficients******

            call iterative_arclength_calc(r, z, ar, br, cr, dr, er, az, bz, cz, dz, ez,&
                s, length, np, torus_switch)

            !************************************************************************************
            !************************************************************************************
            ! Calculation of spline constants and redistribution of nodes


            CALL splinecalc_redist(np, r, z, phi, ar, br, cr, dr, er, az, bz, cz, dz, ez,&
                aphi, bphi, cphi, dpphi, ephi, aphir, bphir, cphir, dphir,&
                ephir, s, rem_pot, vpot, extra_stress, torus_switch, ll, t,&
                u_vortex, w_vortex, N_trap, N_int, deltaPhi, vri, vzi)


            Do l=1,(np+1)
                z_image(l) = -z(l)
            Enddo


            if(torus_switch.eq.1)then

                vpot = 0d0
                arcint = 0d0

                CALL vortpot_n1(np,N_trap,deltaPhi,r,z,vri,vzi,vpot(1))


                CALL arcint_calc(np,N_trap,r,z,vri,vzi,deltaPhi,arcint, u_vortex, w_vortex)


                DO k = 2,(np+1)
                    vpot(k) = vpot(k-1) + arcint(k)  !vpot is potential of vortex ring.
                ENDDO

                DO k= 1,(np+1)
                    phi(k) = rem_pot(k) + vpot(k)
                ENDDO



            endif



            !************************************************************************************
            !************************************************************************************
            !Calculate the volume of the bubble:

            call calc_vol(np, r, ar, br, cr, dr, er, az, bz, cz, dz, ez, s, vol)

            vol = -vol

            vol2 = vol/((4d0/3d0)*pi)
            if((t.eq.0).and.(ll.eq.1))then
                V0 = vol!4d0*pi*( 0.1651d0**3d0 )/3d0      !vol
            endif


            if(mod(t,20).eq.0)then
                write(333,*) time, vol
            endif

            !************************************************************************************
            !************************************************************************************
            ! Evaluation of the boundary integral solution; collocation is performed
            ! over bubble surface only

            if (torus_switch.eq.0) then


                CALL normal_vel_BIE(np, r, z, z_image, phi, ar, br, cr, dr, er, az,&
                    bz, cz, dz, ez, aphi, bphi,&
                    cphi, dpphi, ephi, s, pi, wall_switch, HP)


            else   ! Solve integral eqn for remnant potential for toroidal bubble


                CALL VR_normal_vel_BIE(np, r, z, z_image, rem_pot, ar, br, cr, dr,&
                    er, az, bz, cz, dz, ez,&
                    aphir, bphir, cphir, dphir, ephir, s, pi, wall_switch, HP_rem)


            end if

if(torus_switch.eq.1)then
  ! do i=1,(np+1)
   !   write(*,*) s(i), rem_pot(i), HP_rem(i)
   !enddo
 ! stop
endif
            if(counter.eq.1)then
            !if(torus_switch.eq.1)then
                write(*,*) 'HP after reconnection'
                DO i=1,(np+1)
                    write(*,*) s(i), HP(i)
                ENDDO
                !stop
            endif
            if(torus_switch.eq.1)then
            if(mod(teller,1000).eq.0)then
            do i=1,(np+1)
            !write(555,*) HP(i)
            enddo
            endif
            endif
            !if(teller.eq.10001)then
            !stop
            !endif

            !!call SURFACE(r, z, phi, s, nr, nz, sr, sz, np, n_order,&
            !!              tang_vel, curvature, dphi2_ds2, HP, dphi2_dsdn)


             !SURFACE_SPLINE does the same as above, except uses the cubic splines
             !to calculate things instead. Either can be used.

            if(torus_switch.eq.0)then

                call SURFACE_SPLINE(s, nr, nz, sr, sz, np,&
                    ar, br, cr, dr, er, az, bz, cz, dz, ez, aphi, bphi, cphi, dpphi, ephi,&
                    tang_vel, curvature, dphi2_ds2)


            else


                CALL torus_surf_derivs(np, r, z, s, rem_pot, deltaPhi,&
                    phi, nr, nz, sr, sz, n_order, tang_rem,&
                    tang_vel, dphi2_ds2, curvature, r_curvature, drem2_ds2,&
                    HP_rem, HP, u_vortex, w_vortex)


                !HP(1) = ( HP(2) + HP(np) )/2d0
                !HP(np+1) = HP(1)
                !tang_vel(1) = ( tang_vel(2) + tang_vel(np) )/2d0
                !tang_vel(np+1) = tang_vel(1)


                if((mod(teller,1000).eq.0).and.(ll.eq.1))then
                    write(123,*) 'norm', HP_rem
                    write(123,*) 'tang', tang_rem
                endif

            endif

            if(torus_switch.eq.1)then
               if(ll.eq.1)then
           !   if(mod(teller,1).eq.0)then
               ! write(*,*) 'teller', teller
                !DO i=1,(np+1)
                    !write(*,*) s(i), phi(i), HP(i), tang_vel(i)
               ! ENDDO
                 ! if(teller.eq.5)then
                !     stop
                !  endif
               endif
            endif

            !************************************************************************************
            !************************************************************************************


            if ((torus_switch.eq.1).and.(mod(teller,100).eq.0).and.(ll.eq.5))then
                print *,'*********************************************************'
                print *,'teller = ',teller
                print *,'dpot_dn = ',maxval(abs(HP_rem)), ', dpot_ds = ',maxval(abs(tang_rem))
                print *,'*********************************************************'
            endif

            !************************************************************************************
            !************************************************************************************

            ! Calculation of jet velocity for torodial bubble

            !if(torus_switch.eq.1)then

            ! CALL jetvel_calc(r,z,rem_pot,HP_rem,np,torus_switch,wall_switch,deltaPhi,jet_velocity)

            !endif

            !************************************************************************************
            !************************************************************************************
            ! Stress calculation


            do 12 i = 1, (np + 1)

                !calculate the speed at each point.
                resultant_vel(i) = dsqrt(HP(i)**2 + tang_vel(i)**2)

                !calc radius (this is incorrect for all but spherical case centred at origin)
                radius(i) = dsqrt(r(i)**2 + z(i)**2)

                minrdist = minval(z)

                if(torus_switch.eq.0)then
                    !Determine second normal derivative from forms given in thesis
                    if ((i.eq.1).or.(i.eq.(np + 1))) then
                         !Takes different form on axis (from L'Hopital's rule)
                        dphi2_dn2(i) = (2d0*dphi2_ds2(i) - 2d0*curvature(i)*HP(i))

!write(*,*) i, tang_vel(i), HP(i), dphi2_ds2(i), dphi2_dn2(i)
                    else

                        dphi2_dn2(i) = (dphi2_ds2(i) - curvature(i)*HP(i) + &
                            (1d0/r(i))*(nr(i)*HP(i)+ sr(i)*tang_vel(i)) )


                    end if

                elseif(torus_switch.eq.1)then

                    dphi2_dn2(i) = (dphi2_ds2(i) - curvature(i)*HP(i) + &
                        (1d0/r(i))*(nr(i)*HP(i)+ sr(i)*tang_vel(i)) )

                endif

!write(*,*) i, tang_vel(i), phi(i), HP(i)
                ! MATERIAL MAXWELL
                !Calculating the stress at each intermediate time step using a simple Euler scheme
                if(viscel.eq.1)then

                if(ll.eq.1)then
                  extra_stress_old(i) = extra_stress(i)
                elseif(ll.eq.2)then
                  dtt = dt/2d0
                  extra_stress(i) = (1d0/(1d0 + lambda/dtt))*(-mu*2d0*dphi2_dn2(i) + (lambda/dtt)*extra_stress_old(i))
                elseif(ll.eq.3)then
                  dtt = dt/2d0
                  extra_stress(i) = (1d0/(1d0 + lambda/dtt))*(-mu*2d0*dphi2_dn2(i) + (lambda/dtt)*extra_stress_old(i))
                elseif(ll.eq.4)then
                  dtt = dt
                  extra_stress(i) = (1d0/(1d0 + lambda/dtt))*(-mu*2d0*dphi2_dn2(i) + (lambda/dtt)*extra_stress_old(i))
                elseif(ll.eq.5)then
                  dtt = dt
                  extra_stress(i) = (1d0/(1d0 + lambda/dtt))*(-mu*2d0*dphi2_dn2(i) + (lambda/dtt)*extra_stress_old(i))
                 endif

                 endif

                ! UCM OR OLDROYD-B
                 if(ll.eq.1)then
                      extra_stress_old(i) = extra_stress(i)
                  elseif(ll.eq.2)then     ! backward euler approximation of Maxwell relation, with gamma dot = 2*dphi2_dn2 (page 23)
                      dtt = dt/2d0
                      extra_stress(i) = ( 1d0/(1d0 + lambda/dtt + 2d0*lambda*dphi2_dn2(i)) )*&
                      ( -mu*2d0*dphi2_dn2(i) + (lambda/dtt)*extra_stress_old(i) )
                  elseif(ll.eq.3)then
                      dtt = dt/2d0
                      extra_stress(i) = ( 1d0/(1d0 + lambda/dtt + 2d0*lambda*dphi2_dn2(i)) )*&
                      ( -mu*2d0*dphi2_dn2(i) + (lambda/dtt)*extra_stress_old(i) )
                  elseif(ll.eq.4)then
                      dtt = dt
                     extra_stress(i) = ( 1d0/(1d0 + lambda/dtt + 2d0*lambda*dphi2_dn2(i)) )*&
                      ( -mu*2d0*dphi2_dn2(i) + (lambda/dtt)*extra_stress_old(i) )
                  elseif(ll.eq.5)then
                      dtt = dt
                      extra_stress(i) = ( 1d0/(1d0 + lambda/dtt + 2d0*lambda*dphi2_dn2(i)) )*&
                      ( -mu*2d0*dphi2_dn2(i) + (lambda/dtt)*extra_stress_old(i) )
                  endif


12          continue


!if(torus_switch.eq.1)then
!resultant_vel(1) = ( resultant_vel(2)+resultant_vel(np) )/2d0
!resultant_vel(np+1) = resultant_vel(1)
!endif


  if(ll.eq.1)then

              !  if(pulsebot.gt.(height+1.1d0).and.(vol.lt.100))then
                    do i = 1, (np + 1)
                        abs_ex_str(i) = dabs(extra_stress(i))
                        t_step_den(i) = 1d0 + 0.5d0*resultant_vel(i)**2 + abs_ex_str(i) + eps*(1/vol)**(lam)
                    enddo
                    !Determine the time step from maximum velocity on surface. This version also
                    !includes maximum stess value on surface in determining timestep

                    dphi = maxval(t_step_den)

                    if(torus_switch.eq.0)then
                        dt = dt_max/dphi !Time step dt
                        !dt = 5d-7*vol/V0
                    elseif(torus_switch.eq.1)then
                        dt = dt_cut
                        if(teller.gt.3000)then
                           dt = dt_cut*10d0
                        endif

                    endif

                !elseif(pulsebot.le.(height+1.1d0).and.(vol.lt.100))then
             !   else

                    do i = 1, (np + 1)
                        abs_ex_str(i) = dabs(extra_stress(i))
                    enddo

                    if(torus_switch.eq.0)then
                 !       dt = 1d-5!5d-7*vol/V0
                    elseif(torus_switch.eq.1)then
                        dt = dt_cut
                    endif


               ! endif

                rad = sum(radius)/(np + 1) !average radius
                av_norm_vel = sum(HP)/(np + 1)!average normal velocity

            endif


            centroidr = sum(r)/(np+1)
            centroid = sum(z)/(np+1)

            if(dt.lt.1d-8)then
                dt = 1d-8
            endif
           if(time.lt.12d0)then
            !  dt = 0.005d0
            endif







            !************************************************************************************
            !************************************************************************************
            ! Calculate the energy (should remain constant) to check result


            CALL energy_routine(np, N_trap, r, z, torus_switch, deltaPhi, jet_velocity,&
                phi, HP, rem_pot, lam, wall_switch, vri, vzi,&
                V0, eps, delt, total_energy, E1_app, E1, E2, E3, E4, jet_approx)

            if((ll.eq.1).and.(mod(t,10).eq.0))then
                write(300,*) time, total_energy
                write(200,*) E1, E2, E3, E4
                if((torus_switch.eq.1).and.(mod(teller,50).eq.0))then
                    write(201,*) time, E1, E2, E3, E4
                endif
            endif

            !************************************************************************************
            !************************************************************************************
            ! Bubble centroid position and equivalent radius

            centroid = sum(z)/(np+1)
            eq_rad = ( 3d0*vol/(4d0*pi) )**(1d0/3d0)

            DO i=1,(np+1)
                pyth(i) = ( r(i)**2d0 + (z(i)-height)**2d0 )**(0.5d0)
            ENDDO
            DO i=1,(np+1)
                devi(i) = pyth(i) - sum(pyth)/(np+1)
            ENDDO

            if((ll.eq.1).and.(mod(t,10).eq.0))then
                write(383,*) time, centroid, eq_rad, maxval(abs(devi))
            endif



    !************************************************************************************
    !************************************************************************************
    ! Pressure pulse description (muoltiple pulses)

            if((ll.eq.1).and.(preshswitch.eq.1))then
            !if(ll.eq.1)then


             !   if(ddd.eq.0)then

                    indist = 0d0!20.490d0

                   ! if(t.eq.0)then
                       !pmid = 30.18d0/( R0*1000000d0 ) - time*Us
                       pmid = height + inrad + 15d0 - time*Us
                       if(t.eq.0)then
                          pulsebot = height + inrad + indist
                         ! pulsetop = 2d0*pmid - pulsebot
                          pb0 = pulsebot
                        !  pt0 = pulsetop
                       endif
                  !  else
                      ! pulsetop = pt0 - time*Us
                       pulsebot = pb0 - time*Us
                  !     pmid = ( pulsetop + pulsebot )/2d0
                  !  endif

                    !pulsechange = pulsebot + (pulsetop-pulsebot)/7d0
                    !pmid = ( pulsetop + pulsebot )/2d0

                    if((pulsebot.lt.0).and.(wall_switch.eq.1))then
                        ddd = 1
                    endif

                if((ddd.eq.1).and.(wall_switch.eq.1))then

                    if(ccc.eq.0)then
                        thit = time
                        pt20 = 0d0
                      !  pb20 = -pulsetop
                        pmid20 = -15d0!-pulsetop/2d0
                    endif

                    ccc = ccc + 1
                  !  pulsebot2 = -pt0 + pb0 + (time - thit)*Us
                  !  pulsetop2 = (time - thit)*Us
                  !  pulsechange2 = pulsetop2 - (pulsetop2-pulsebot2)/7d0
                    pmid2 = pmid20 + (time - thit)*Us


                   ! write(*,*) 'pulses2', pulsetop2, pulsebot2, pulsechange2

                    do i=1,(np+1)

                        Pinf2(i) = (Pa/ppc)*sin(z(i)-pmid2)*&
                            exp( -(1d0/36d0)*( (z(i)-pmid2)**2d0  ) )
                    enddo

                endif


                do i=1,(np+1)
                  !  if((z(i).ge.pulsebot).and.(z(i).le.pulsetop))then
                        Pinf(i) = Pinf2(i) + PP0/ppc + &
                            (Pa/ppc)*sin(z(i)-pmid)*&
                            exp( -(1d0/36d0)*( (z(i)-pmid)**2d0  ) )
                 !   else
                 !       Pinf(i) = Pinf2(i) + Pref
                  !  endif
                enddo

!if(mod(t,30).eq.0)then
!write(*,*) time, Pinf(1), &
!           PP0/ppc + (Pa/ppc)*sin(time - 15d0)*exp( -(1d0/36d0)*( (time - 15d0)**2d0  ) )
!endif

!if(ll.eq.1)then
!if(mod(t,20).eq.0)then
!write(*,*) time, Pinf(1)
!endif
!endif


            endif



            !************************************************************************************
            !************************************************************************************
            ! Finding pressure and velocity fields

            if(intern.eq.1)then

                if(ll.eq.1)then

                    !if(torus_switch.eq.1)then


                        rmin = minval(r)
                        temp = minloc(r)
                        zmin = z( int(temp(1)) )

                        gi(1)=-0.93246951420315202781
                        gi(2)=-0.66120938646626451366
                        gi(3)=-0.23861918608319690863     !6-gauss points
                        gi(4)=0.23861918608319690863
                        gi(5)=0.66120938646626451366
                        gi(6)=0.93246951420315202781

                        DO i = 1,(no_wall)

                            !r_wall(i) = -6d0 + 12d0*(dble(i)-1d0)/dble(no_wall-1d0)
                            r_wall(i) = 0d0!-1.5d0 + 3d0*(dble(i)-1d0)/dble(no_wall-1d0)
                            z_wall(i) = 0d0

                        ENDDO

                        CALL i2nternal_quantities(np, no_wall, r_wall, z_wall,&
                            r, z, z_image, preshwall,&
                            HP, absvel, phi_int2, phi_int_old2, dh,&
                            ar, br, cr, dr, er,&
                            az, bz, cz, dz, ez,&
                            aphi, bphi, cphi, dpphi, ephi, phi,&
                            vel_x2, vel_y2, wall_switch, torus_switch, s, dt,&
                            rem_pot, rem_int2, aphir, bphir, cphir, dphir, ephir,&
                            deltaPhi, vri, vzi, vort_int2, HP_rem, dt_cut)

               !         if(t.eq.0)then
               !            jet_hit = (z(1) - z(np + 1))/2d0
               !         endif

                       ! if(jet_hit.lt.0.02d0)then
                       !   DO i=1,(no_wall)
                       !      write(*,*) r_wall(i), preshwall(i)  ! Pressure along the wall
                       !   ENDDO
                       ! stop
                       ! endif


             if(preshswitch.eq.1)then

               preshwall(1) = preshwall(1) + &
                 (Pa/ppc)*sin(z(i)-pmid)*&
                            exp( -(1d0/36d0)*( (z(i)-pmid)**2d0  ) )

             endif


                        !if((teller.eq.0).and.(mod(t,6).eq.0))then
                        if(torus_switch.eq.0)then
                        if(mod(t,6).eq.0)then

                            write(234,*) time, preshwall(1), maxval(PBB), minval(PBB)!, preshwall(2), preshwall(3)

                        endif
                        elseif(torus_switch.eq.1)then

                          if(mod(teller,30).eq.0)then
                           write(234,*) time, preshwall(1), maxval(PBB), minval(PBB)!, preshwall(2), preshwall(3)
                          endif

                        endif


                        DO i = 1,(no_int)

                            r_internal(i) = (rmin/2d0)*gi(i) + rmin/2d0
                            z_internal(i) = zmin !0d0

                        ENDDO

                        r_internal(no_int+1) = 0d0
                        z_internal(no_int+1) = zmin


                        CALL internal_quantities(np, no_int, r_internal, z_internal,&
                            r, z, z_image, presh,&
                            HP, absvel, phi_int, phi_int_old, dh,&
                            ar, br, cr, dr, er,&
                            az, bz, cz, dz, ez,&
                            aphi, bphi, cphi, dpphi, ephi, phi,&
                            vel_x, vel_y, wall_switch, torus_switch, s, dt,&
                            rem_pot, rem_int, aphir, bphir, cphir, dphir, ephir,&
                            deltaPhi, vri, vzi, vort_int, HP_rem, dt_cut)


                        ! jet_velocity = vel_y(1)
                        DO i = 1,no_int

                            jet_approx(i) = vel_y(i)   ! d/dz or remnant potential over torus eye

                        ENDDO

                        ! jet is d/dz of remnant potential + w^vr(0,zmin)
                        jett = vel_y(no_int+1) + (deltaPhi*(vri**2d0)/2d0)*( &
                        ((zmin+vzi)**2d0 + vri**2d0)**(-1.5d0) - ((zmin-vzi)**2d0 + vri**2d0)**(-1.5d0) )


                        ! Pressure at midpoint of wall
                        if((teller.eq.0).and.(mod(t,2).eq.0))then

                          !  write(234,*) time, presh(no_int+1)

                        elseif((torus_switch.eq.1).and.(mod(t,2).eq.0))then

                           ! write(234,*) time, presh(no_int+1)

                        endif

                    !endif

                endif

            endif





            !************************************************************************************
            !************************************************************************************
            ! Updating bubble surface and potential

            CALL updating_surf(np, ll, r, z, phi, rem_pot, torus_switch, r_new,&
                z_new, phi_new, rem_new, r_old, z_old, phi_old, rem_pot_old, dt,&
                N_trap, deltaPhi, vri, vzi, resultant_vel, Pinf,&
                nr, nz, sr, sz, delt, eps, HP, tang_vel,&
                HP_rem, tang_rem, V0, vol, lam, extra_stress, extra_stress_old, extra_stress_new, k1_r,&
                k2_r, k3_r, k4_r, k1_z, k2_z, k3_z, k4_z, k1_phi, k2_phi,&
                k3_phi, k4_phi, k1_rem, k2_rem, k3_rem, k4_rem, Webinv, curvature,&
                u_vortex, w_vortex, dphi2_dn2, lambda, mu, k1_t, k2_t, k3_t, k4_t, viscel, EE,&
                chi, mush, shw, inrad, eq_rad, PBB, ppc, PP0 )


            !************************************************************************************
            !************************************************************************************
            ! Keep node 1 and N+1 connected for toroidal bubble

            if (torus_switch.eq.1) then
                r_new(1) = r_new(np+1)
                z_new(1) = z_new(np+1)
                rem_new(1) = rem_new(np+1)
            endif

101     continue


        !jet hit measures distance between jet tip and bubble underside
        jet_hit = (z(1) - z(np + 1))/2d0
        jet_hit = abs(jet_hit)
        if(t.eq.50)then
          write(*,*) 'tteller2', tteller2
        endif

           !If that distance is small bubble becomes toroidal
        if((jet_hit.lt.1d-2).and.(torus_switch.eq.0).and.(tteller2.gt.300))then       !calculate first time step just after impact

            write(101010,*) 'TRANSITION TO TOROIDAL', t, time

           ! stop
            write(*,*) 'HP before'
            DO i=1,(np+1)
                write(*,*) s(i), r(i), z(i), HP(i)
            ENDDO
           ! stop

            counter = 0
            teller3 = teller3 + 1


            ! Calculate energy just before transition
            CALL energy_calc(r, z, np, N_trap, ar, br, cr, dr, er,&
                aphihp, bphihp, cphihp, dphihp, ephihp,&
                deltaPhi, phi_temp, rem_pot, HP, phiHP, s, torus_switch, vol, V0, lam, total_energy,&
                eps, delt, E1, E2, E3, E4, wall_switch,&
                jet_velocity, vri, vzi, E1_app, jet_approx)

            write(200,*) E1, E2, E3, E4

            call reflect_surface(r_graph, z_graph, r, z, np)
            write(998,*) 'VARIABLES JUST BEFORE SMOOTHING = "r", "z"'
            write(998,*) 'ZONE T="time:',time,'",I=',(np + 1),',J=',1,',F=POINT'

            do i = 1, (2*np + 1) !! Write position of bubble surface to file 999
                write(999,*) r_graph(i), z_graph(i)
            enddo
            do i = 1, (2*np + 1) !! Write position of bubble surface to file 999
                write(1000,*) r_graph(i), z_graph(i)
            enddo
            do i = 1, (2*np + 1) !! Write position of bubble surface to file 999
                write(1001,*) r_graph(i), z_graph(i)
            enddo


            torus_switch = 1


            deltaT = dt/10      !time step for Euler stepping between just prior and just after impact, should be very small

            do 541 i = 1, (np + 1)          !r,z,phi just prior to impact
                r(i) = r_new(i)
                z(i) = z_new(i)
                phi(i) = phi_new(i)
                extra_stress(i) = extra_stress_new(i)
541         continue


            !****************************************************************************************
            !****************************************************************************************


            deltaPhi = (1d0)*(phi(np + 1) - phi(1))
            print *,'deltaPhi = ',deltaPhi
            print *,'HP', HP
            print *, 't', t

            vri = 0d0
            vzi = 0d0

            !vri = sum(r)/(np+1)
            !vzi = sum(z)/(np+1)



            minrr = minval(r)
            minzz = minval(z)
            maxrr = maxval(r)
            maxzz = maxval(z)

            DO j=1,(N_int+1)
                DO i=1,(N_int+1)

                    rr_int(i+(j-1)*(N_int+1)) = minrr + (i-1)*(maxrr-minrr)/(dble(N_int))
                    zz_int(i+(j-1)*(N_int+1)) = maxzz + (j-1)*(minzz-maxzz)/(dble(N_int))

                ENDDO
            ENDDO

            DO i= 1,( (N_int+1)*(N_int+1) )

                DO j=1,(np+1)
                    mindist(i,j) = ( (r(j) - rr_int(i))**2d0 + (z(j) - zz_int(i))**2d0 )**0.5d0
                ENDDO
                mind(i) = minval(mindist(i,:))

            ENDDO

            INOUTT = 0

            DO i=1,( (N_int+1)*(N_int+1) )

                CALL PNPOLY(rr_int(i),zz_int(i),r,z,np+1,INOUTT(i))

                if(INOUTT(i).ne.1)then
                    mind(i) = 0d0
                endif

            ENDDO

            loc = maxloc(mind)
            vri = rr_int( int(loc(1)) )
            vzi = zz_int( int(loc(1)) )
            write(*,*) 'a,c', vri, vzi

            !Original closest distance to bubble from vortex ring.

            !DO i=1,(np+1)
            !   low_r_orig(i) = ( (r(i) - vri)**2d0 + (z(i) - vzi)**2d0 )
            !ENDDO

            !   r_min_orig = minval( low_r_orig )

            !write(*,*) 'rorig', r_min_orig
            !write(*,*) 'a,c', vri, vzi

            !Calculating potential of vortex ring
            CALL vortpot_n1( np,N_trap,deltaPhi,r,z,vri,vzi,vpot(1) )


            CALL arcint_calc2( np,N_int,N_trap,r,z,vri,vzi,deltaPhi,arcint,u_vortex,w_vortex)


            DO k = 2, (np+1)
                vpot(k) = vpot(k-1) + arcint(k)  !vpot is potential of vortex ring.
            ENDDO

            !CALL new_vortpot(r, z, np, vri, vzi, deltaPhi, vpot)

            ! Now remnant potential is calculated using the existing potential and the vortex
            ! ring potential that has just been calculated.

            !vpot(1) = vpot(np+1)-deltaPhi

            DO i = 1, (np+1)
                rem_pot(i) = phi(i) - vpot(i)
               ! rem_pot(i) = phi(i) - vrphi(i)
            ENDDO



            write(*,*) deltaPhi, vpot(np+1)-vpot(1), vrphi(np+1)-vrphi(1)
            write(*,*) 'phi, vortex and remnant potentials'
            DO i=1,(np+1)
                write(*,*) r(i), z(i), phi(i), vpot(i), rem_pot(i)
            ENDDO
            !stop


            !*****************************************************************************************
            !*****************************************************************************************


            npnew = np
            deallocate(r_new, z_new, phi_new, extra_stress_new, phi_temp, rem_new, vpot_new)
            allocate(r_new(npnew + 1), z_new(npnew + 1), phi_new(npnew + 1),&
                extra_stress_new(npnew + 1), phi_temp(npnew + 1), rem_new(npnew + 1),&
                vpot_new(npnew + 1))


            r_new = 0d0
            z_new = 0d0
            rem_new = 0d0

            r_new(1) = (r(1) + r(np+1) + r(2) + r(np))/4d0                   !r,z and rem_pot at node 1/(np_new + 1) is taken to be
            r_new(npnew + 1) = r_new(1)                     !the average of previous nodes 2 and np.
            z_new(1) = (z(1) + z(np+1) + z(2) + z(np))/4d0
            z_new(npnew + 1) = z_new(1)
            rem_new(1) = (rem_pot(1) + rem_pot(np+1) + rem_pot(2) + rem_pot(np))/4d0
            rem_new(npnew + 1) = rem_new(1)
            extra_stress_new(1) = (extra_stress(1) + extra_stress(np+1) + extra_stress(2) + extra_stress(np))/4d0
            extra_stress_new(npnew+1) = extra_stress_new(1)

            DO i=2,(npnew)                                  ! The rest of the nodes stay the same, except
                r_new(i) = r(i)                            ! nodes 1,2,np and np+1 are deleted. So we have
                z_new(i) = z(i)                            ! three less nodes.
                rem_new(i) = rem_pot(i)
                extra_stress_new(i) = extra_stress(i)
                vpot_new(i) = vpot(i)
            ENDDO




            call reflect_surface_torus(r_graph_aft, z_graph_aft, r_graphop, z_graphop, r_new, z_new,&
                npnew)

            write(9998,*) 'VARIABLES JUST AFTER SMOOTHING = "r", "z"'
            write(9998,*) 'ZONE T="time:',time,'",I=',(np+1),',J=',1,',F=POINT'

            do i = 1, (npnew + 1) !! Write position of bubble surface to file 999
                write(9999,*) r_graph_aft(i), z_graph_aft(i)
            enddo
            do i = 1, (npnew + 1)
                write(9999,*) r_graphop(i), z_graphop(i)
            enddo


            np = npnew                              ! Redefine number of segments


            deallocate(ar, br, cr, dr, er, az, bz, cz, dz, ez, aphir, bphir,&
                cphir, dphir, ephir, HP_rem)
            allocate(ar(np + 1), br(np+1), cr(np+1), dr(np+1), er(np+1), az(np+1), bz(np+1),&
                cz(np+1), dz(np+1), ez(np+1), aphir(np+1), bphir(np+1), cphir(np+1),&
                dphir(np+1), ephir(np+1), HP_rem(np+1) )



            !Re-allocate arrays with size dependent on np:

            deallocate(r,z,phi,HP,STAT=P)

            deallocate(G, H, const, nr,&
                nz, A1, A2, radius, tang_vel, sr, sz, resultant_vel,&
                r_new_arc, z_new_arc, curvature, viscous_term,&
                dphi2_ds2, r_smooth, z_smooth, phi_smooth, z_image,&
                r_graphop, z_graphop,&
                dphi2_dsdn, extra_stress, STAT=P)



            deallocate(dphi2_dn2, dphi2_dsdn_smooth, dphi2_ds2_smooth,&
                s_new, r_old, z_old, phi_old, k1_r, k2_r, k1_z, k2_z,&
                k1_phi, k2_phi, k3_phi, k4_phi, k3_r, k4_r, k3_z, k4_z, STAT=P)



            deallocate(extra_stress_old, pressure_surf, pressure_surf_2,&
                vel_x_surf, vel_y_surf, aTs, bTs, cTs, dTs, eTs, &
                ex_str_new_arc, ex_str_smooth,STAT=P)


            deallocate(abs_ex_str,t_step_den,G2,H2,A12,const2,HPnew,HP2,&
                ar_s, br_s, cr_s, dr_s, er_s,&
                az_s, bz_s, cz_s, dz_s, ez_s, s_s, aphi_s, bphi_s,&
                cphi_s, dphi_s, ephi_s)



            !Vortex variables:
            deallocate(arcint, vpot, rem_pot, resultant_rem,&
                u_vortex, w_vortex, tempr, k1_rem, k2_rem,&
                k3_rem, k4_rem, rem_pot_old, rem_pot_new,&
                HP_rem_new,&
                drem2_ds2, drem2_dn2,&
                G2_rem, HP2_rem, s, low_r, low_z, low_r_orig, low_z_orig, tempy,&
                aphi_temp, bphi_temp, cphi_temp, dphi_temp, ephi_temp, adphidn,&
                bdphidn, cdphidn, ddphidn, edphidn,&
                phiHP, aphihp, bphihp, cphihp, dphihp, ephihp, tang_rem, aHP, bHP,&
                cHP, dHP, eHP,&
                remspline, s_int, drem, d2rem, pyth, minz, ztemp,&
                rtester, ztester, Pinf, xts, xtempsp, vrphi, resultant_test)


            allocate(  r(np + 1), z(np + 1), phi(np + 1), G(np + 1, np + 1),&
                HP(np + 1), H(np + 1), &
                const(np + 1), nr(np + 1),&
                nz(np + 1), A1(np + 1), A2(np + 1),&
                radius(np + 1), tang_vel(np + 1),&
                sr(np + 1), sz(np + 1), resultant_vel(np + 1),&
                r_new_arc(np + 1), z_new_arc(np + 1),&
                curvature(np + 1), viscous_term(np + 1),&
                dphi2_ds2(np + 1), r_smooth(np + 1), z_smooth(np + 1),&
                phi_smooth(np + 1), z_image(np + 1),&
                r_graphop(np + 1), z_graphop(np + 1),&
                dphi2_dsdn(np + 1), extra_stress(np + 1),&
                dphi2_dn2(np + 1), dphi2_dsdn_smooth(np + 1),&
                dphi2_ds2_smooth(np + 1),s_new(np + 1), r_old(np + 1),&
                z_old(np + 1), phi_old(np + 1),&
                k1_r(np + 1), k2_r(np + 1),  k1_z(np + 1), k2_z(np + 1),&
                k1_phi(np + 1), k2_phi(np + 1),k3_phi(np + 1), k4_phi(np + 1),&
                k3_r(np + 1), k4_r(np + 1), k3_z(np + 1), k4_z(np + 1),&
                extra_stress_old(np + 1),pressure_surf(np + 1), pressure_surf_2(2*np + 1),&
                vel_x_surf(np + 1), vel_y_surf(np + 1),&
                aTs(np + 1), bTs(np + 1), cTs(np + 1),&
                dTs(np + 1), eTs(np + 1),&
                ex_str_new_arc(np + 1), ex_str_smooth(np + 1),&
                abs_ex_str(np + 1), t_step_den(np + 1),&
                G2(np, np), H2(np), A12(np), const2(np), HPnew(np+1),&
                HP2(np + 1), ar_s(np), br_s(np), cr_s(np), dr_s(np), er_s(np),&
                az_s(np), bz_s(np), cz_s(np), dz_s(np), ez_s(np), s_s(np),&
                aphi_s(np), bphi_s(np), cphi_s(np),&
                dphi_s(np), ephi_s(np),&
                arcint(np + 1), vpot(np + 1), rem_pot(np + 1),&
                resultant_rem(np + 1), u_vortex(np + 1),&
                w_vortex(np + 1), tempr(np + 1),&
                k1_rem(np + 1), k2_rem(np+1), k3_rem(np + 1),&
                k4_rem(np + 1), rem_pot_old(np + 1),&
                rem_pot_new(np + 1),&
                HP_rem_new(np + 1),&
                drem2_ds2(np + 1), drem2_dn2(np + 1),&
                G2_rem(np,np-1), HP2_rem(np), s(np + 1),&
                aphi_temp(np+1), bphi_temp(np+1), cphi_temp(np+1),&
                dphi_temp(np+1), ephi_temp(np + 1),&
                adphidn(np + 1), bdphidn(np + 1), cdphidn(np + 1),&
                ddphidn(np + 1), edphidn(np + 1),&
                phiHP(np + 1), aphihp(np + 1), bphihp(np + 1),&
                cphihp(np + 1), dphihp(np + 1), ephihp(np + 1),&
                tang_rem(np + 1), aHP(np+1), bHP(np+1),&
                cHP(np+1), dHP(np+1), eHP(np+1), minz(np + 1), ztemp(np + 1),&
                rtester(np+1), ztester(np+1), Pinf(np + 1),&
                pyth(np + 1), xts(np+1,N_trap+1),&
                xtempsp(np+1,N_trap+1), vrphi(np+1), resultant_test(np+1) )

            allocate( low_r(np + 1), low_z(np + 1), low_r_orig(np + 1), low_z_orig(np + 1),&
                tempy(np + 1),remspline(np,N_int+1),&
                s_int(np,N_int+1), drem(np,N_int+1),&
                d2rem(np,N_int+1)  )

            extra_stress = extra_stress_new

            !vri = sum(r_new)/(np+1)
            !vzi = sum(z_new)/(np+1)

            write(*,*) 'New node positions'
            DO i=1,(np+1)
                write(*,*) r_new(i), z_new(i)
            ENDDO



            !Recalculating potential of vortex ring for redistributed nodes.
            CALL vortpot_n1( np,N_trap,deltaPhi,r_new,z_new,vri,vzi,vpot(1) )

            arcint = 0d0
            CALL arcint_calc2( np,N_int,N_trap,r_new,z_new,vri,vzi,deltaPhi,arcint, u_vortex, w_vortex)


            DO k = 2, (np+1)
                vpot(k) = vpot(k-1) + arcint(k)  !vpot is potential of vortex ring.
            ENDDO

            !write(*,*) 'vort,u,w'
            !DO k=1,(np+1)
            !   write(*,*) vpot(k), u_vortex(k), w_vortex(k)
            !ENDDO

            !CALL new_vortpot(r_new, z_new, np, vri, vzi, deltaPhi, vrphi, u_vortex, w_vortex)

            write(*,*) 'phi etc once moved'
            DO k=1,(np+1)
                phi_new(k) = vpot(k) + rem_new(k)
                write(*,*) phi_new(k), vpot(k), rem_new(k)
               ! write(*,*) phi_new(k), vpot(k), rem_new(k)
            ENDDO
            !stop

            deltaPhi = (1d0)*( phi_new(np+1) - phi_new(1) )



        endif


        !********************************************************************************************
        !********************************************************************************************


        ! Reconnection of bubble:
        minimumR = minval(r_new,1)

        if((torus_switch.eq.1).and.(minimumR.lt.1d-2).and.(teller.gt.50))then


            write(101010,*) 'RECONNECTED BUBBLE', t, time
            teller3 = teller3 + 1
            teller = 0

            write(*,*) 'reconnection surface'
            DO i=1,(np+1)
                write(*,*) s(i), r_new(i), z_new(i), rem_new(i)
            ENDDO
            write(*,*) 'reconnection phistuff'
            DO i=1,(np+1)
                write(*,*) s(i), rem_new(i), phi(i), HP(i)
            ENDDO

           ! rem_pot(np+1) = rem_pot(1)


            tteller2 = 0
            torus_switch = 0
            teller = 0


            minz = minloc(r)
            write(*,*) 'minr', minz

            z(1) = ( z_new(int(minz(1))) + z_new(int(minz(1)+1)) )/2d0
            z(np+1) = ( z_new(int(minz(1))) + z_new(int(minz(1))-1) )/2d0
            r(1) = 0d0
            r(np+1) = 0d0
            rem_pot(1) = ( rem_new(int(minz(1))) + rem_new(int(minz(1)+1)) )/2d0
            rem_pot(np+1) = ( rem_new(int(minz(1))) + rem_new(int(minz(1)-1)) )/2d0

            !z(1) = z_new(int(minz(1)))
            !z(np+1) = z_new(int(minz(1))+1)
            !r(1) = 0d0
            !r(np+1) = 0d0
            !rem_pot(1) = rem_new(int(minz(1)))
            !rem_pot(np+1) = rem_new(int(minz(1))+1)


            DO i=2,(np+2-int(minz(1)))
                r(i) = r_new(int(minz(1))+i-1)
            ENDDO

            DO i=1,(int(minz(1)-2))
                r(np+1-i) =  r_new(int(minz(1))-i)
            ENDDO

            DO i=2,(np+2-int(minz(1)))
                z(i) = z_new(int(minz(1))+i-1)
            ENDDO

            DO i=1,(int(minz(1)-2))
                z(np+1-i) =  z_new(int(minz(1))-i)
            ENDDO

            DO i=2,(np+2-int(minz(1)))
                rem_pot(i) = rem_new(int(minz(1))+i-1)
            ENDDO

            DO i=1,(int(minz(1)-2))
                rem_pot(np+1-i) =  rem_new(int(minz(1))-i)
            ENDDO

            z(1) = ( z_new(int(minz(1))) + z_new(int(minz(1)+1)) )/2d0
            z(np+1) = ( z_new(int(minz(1))) + z_new(int(minz(1))-1) )/2d0
            r(1) = 0d0
            r(np+1) = 0d0
            rem_pot(1) = ( rem_new(int(minz(1))) + rem_new(int(minz(1)+1)) )/2d0
            rem_pot(np+1) = ( rem_new(int(minz(1))) + rem_new(int(minz(1)-1)) )/2d0


            do 76 l = 1, (np + 1)
                z_image(l) = -z(l) !Define new image bubble surface
                phi(l) = 0d0
76          continue


            call reflect_surface(r_graph, z_graph, r, z, np)

            write(998,*) 'VARIABLES = "r", "z"'
            write(998,*) 'ZONE T="time:',time,'",I=',(np + 1),',J=',1,',F=POINT'

            do i = 1, (2*np + 1) !! Write position of bubble surface to file 999
                write(997,*) r_graph(i), z_graph(i)
            enddo

            vri = 0d0
            vzi = 0d0


            write(*,*) 'new positions'
            DO i=1,(np+1)
                write(*,*) s(i), r(i), z(i), rem_pot(i)
            ENDDO


            vri = sum(r)/(np+1)
            vzi = sum(z)/(np+1)

            write(*,*) 'deltaPhi', deltaPhi

            !Calculating potential of vortex ring
            CALL vortpot_n1( np,N_trap,deltaPhi,r,z,vri,vzi,vpot(1) )


            CALL arcint_calc2( np,N_int,N_trap,r,z,vri,vzi,deltaPhi,arcint,u_vortex,w_vortex)


            DO k = 2, (np+1)
                vpot(k) = vpot(k-1) + arcint(k)  !vpot is potential of vortex ring.
            ENDDO


            DO i = 1, (np+1)
                rem_new(i) = rem_pot(i)
                !phi(i) = rem_new(i) + vpot(i)
                !phi_new(i) = phi(i)
                r_new(i) = r(i)
                z_new(i) = z(i)
                extra_stress_new(i) = extra_stress(i)
            ENDDO


            DO i=1,(np+1)
                write(*,*) rem_new(i), vpot(i), phi(i)
            ENDDO


        endif



        !********************************************************************************************
        !********************************************************************************************


        !Also if the time step is too small, it suggests that a velocity is too large and
        !some instability has crept in...
        if(dt.lt.1d-9)then
            DO i=1,(np+1)
              write(*,*) r(i), z(i), phi(i), HP(i)
            ENDDO

            write(*,*) 'time step too small'
            stop
        endif

        if(torus_switch.eq.0)then
            tteller2 = tteller2 + 1
        endif
        if(torus_switch.eq.1) then
            teller = teller + 1
        endif


        if(wall_switch.eq.1)then
        if(minval(z_new).lt.-0.1d0)then
        write(*,*) 'bub below wall'
        DO i=1,(np+1)
           write(*,*) r_new(i), z_new(i)
        ENDDO
        stop
        endif
        endif

        if((torus_switch.eq.1).and.(teller.eq.1000000))then
            print*,'teller exceeds limit'
            stop
        endif

        if(torus_switch.eq.0)then
        if(mod(t,20).eq.0)then
            ! write(*,*) time, rad
            if(mod(t,20).eq.0)then
                write(*,*) time, pulsetop, maxval(HP), Pinf(1), Pinf2(1), jet_hit!total_energy, jet_hit!rad, jet_hit, maxval(abs(devi))!, total_energy!jet_hit !HP(1)
            !   write(*,*) time, eq_rad, maxval(abs(devi)), Pinf(1), Pinf2(1)
            endif
            write(666,*) time, rad, minrdist, Pinf(1)
        endif
        endif

        !Write time and jet velocity to file
        if(torus_switch.eq.0)then
            if(mod(t,10).eq.0)then
                write(888,*) time, HP(1)!, HP(1) + HP(np+1)
            endif
        elseif(torus_switch.eq.1)then
           if(mod(teller,20).eq.0)then
            write(*,*) time, phi(1), HP(1), total_energy, Pinf(1), Pinf2(1)

           endif
           if(mod(teller,20).eq.0)then
            write(888,*) time, jett
            write(555,*) time, jett
           endif
        endif
        !update time step
        time = time + dt

    !Then, loop done so back to start
100 continue



    !close data files
    close(999)        ! file that will contain the bubble surface data
    close(1000)
    close(1001)
    close(998)
    close(888)               ! file to which jet velocity is written
    close(333)                ! file to which volume is written
    close(444)          ! contains only the volume data after torus formation
    close(555)    ! contains only the jet velocity data after torus formation
    close(9999)       !bubble surface data after transition
    close(99991)
    close(9998)
    close(99998)
    close(711)
    close(997)
    close(123)
    close(666)
    close(200)
    close(300)
    close(201)
    close(301)
    close(401)
    close(501)
    close(456)
    close(567)
    close(234)
    close(383)
    close(484)
    close(101010)




 !Finally end program
end program pressure_pulse_GAUSSIAN_vr


SUBROUTINE vrupdate(rr,zz,pphi,rem_pot,vpot,N,a,c,&
    N_trap, N_int, deltaPhi,&
    u_vortex, w_vortex, s, time)

    ! This routine calculates whether the vortex ring needs relocating (if it is too close to
    ! bubble surface) and updates it if necessary.

    INTEGER                          :: N, k, i, N_int, INOUT((N_int+1)*(N_int+1)), j
    DOUBLE PRECISION                 :: a, c, r_min, deltaPhi, maxs,&
        minr, minz, maxr, maxz, time
    DOUBLE PRECISION, DIMENSION(N+1) :: low_r, rr, zz, pphi, rem_pot, vpot, arcint,&
        u_vortex, w_vortex, s
    DOUBLE PRECISION, DIMENSION(N)   :: ds
    DOUBLE PRECISION, DIMENSION( (N_int+1)*(N_int+1) ) :: r_int, z_int, mind, loc
    DOUBLE PRECISION, DIMENSION( (N_int+1)*(N_int+1),N+1 ) :: mindist


    DO i=1,(N)
        ds(i) = s(i+1) - s(i)
    ENDDO
    maxs = 1.5d0*maxval(ds)

    ! write(*,*) 'r,z'
    DO i=1,(N+1)
        low_r(i) = ( (rr(i) - a)**2d0 + (zz(i) - c)**2d0 )**0.5d0
      ! write(*,*) rr(i), zz(i), low_r(i)
    ENDDO

    r_min = minval( low_r )

    !write(*,*) r_min, maxs


    if(r_min.lt.maxs)then

        write(*,*) 'Vortex relocation'
        write(*,*) time

        !DO i=1,(N+1)
        !  pphi(i) = rem_pot(i) + vpot(i)
        !ENDDO

        write(*,*) 'circulation = ', ( pphi(N+1)-pphi(1) )
        vpot = 0d0

        a = 0d0
        c = 0d0

         ! write(*,*) maxs, r_min

        minr = minval(rr)
        minz = minval(zz)
        maxr = maxval(rr)
        maxz = maxval(zz)

        ! write(*,*) 'min', minz, maxz, minr, maxr
         !write(*,*) 'inout'
        DO j=1,(N_int+1)
            DO i=1,(N_int+1)

                r_int(i+(j-1)*(N_int+1)) = minr + (i-1)*(maxr-minr)/(dble(N_int))
                z_int(i+(j-1)*(N_int+1)) = maxz + (j-1)*(minz-maxz)/(dble(N_int))

            ENDDO
        ENDDO

        DO i= 1,( (N_int+1)*(N_int+1) )

            DO j=1,(N+1)
                mindist(i,j) = ( (rr(j) - r_int(i))**2d0 + (zz(j) - z_int(i))**2d0 )**0.5d0
            ENDDO
            mind(i) = minval(mindist(i,:))
         !write(*,*) r_int(i), z_int(i), mind(i)

        ENDDO


        DO i=1,( (N_int+1)*(N_int+1) )

            CALL PNPOLY(r_int(i),z_int(i),rr,zz,N+1,INOUT(i))
            ! write(*,*) r_int(i), z_int(i), INOUT(i)
            if(INOUT(i).ne.1)then
                mind(i) = 0d0
            endif

        ENDDO

        loc = maxloc(mind)
        a = r_int( int(loc(1)) )
        c = z_int( int(loc(1)) )
        write(*,*) 'a,c', a, c

       ! a = sum(rr)/(N+1)
       ! c = sum(zz)/(N+1)

        vpot = 0d0
        arcint = 0d0

        !Calculating potential of vortex ring
        CALL vortpot_n1( N,N_trap,deltaPhi,rr,zz,a,c,vpot(1) )


        CALL arcint_calc( N, N_trap, rr, zz, a, c, deltaPhi, arcint, u_vortex, w_vortex)

        DO k = 2, (N+1)
            vpot(k) = vpot(k-1) + arcint(k)  !vpot is potential of vortex ring.
        ENDDO

        !CALL new_vortpot(rr, zz, N, a, c, deltaPhi, vpot)

       ! u_vortex = 0d0
      !  w_vortex = 0d0

           ! Now remnant potential is calculated using the existing potential and the vortex
           ! ring potential that has just been calculated.

        write(*,*) 'new phi etc, if relocated'
        DO i = 1, (N+1)
            rem_pot(i) = pphi(i) - vpot(i)
            write(*,*) rr(i), zz(i), pphi(i), vpot(i), rem_pot(i)
        ENDDO

        rem_pot(N+1) = rem_pot(1)
        !stop



    endif


    RETURN

END SUBROUTINE


SUBROUTINE plot_surface(N, r, z, torus_switch, ll, t, t1, t1a, t1b, t2, t2a, t3, t4,&
    teller, teller3, pulsebot, pulsetop, time)

    INTEGER          :: N, t, t1, t1a, t1b, t2, t2a, t3, t4, ll, torus_switch, teller, teller3, i
    DOUBLE PRECISION :: r(N+1), z(N+1), r_graph_aft(N+1), z_graph_aft(N+1),&
        r_graphop(N+1), z_graphop(N+1), r_graph(2*N+1), z_graph(2*N+1),&
        pulsebot, pulsetop, time

            t1 = 450
            t1a = 70
            t1b = 1200
            t2 = 150
            t2a = 500
            t3 = 15000
            t4 = 500


    !  first singly-connected phase
    if((ll.eq.1).and.(torus_switch.eq.0).and.(teller3.eq.0).and.(mod(t,t1).eq.0))then

        call reflect_surface(r_graph, z_graph, r, z, N)

        write(998,*) 'VARIABLES = "r", "z"'
        write(998,*) 'ZONE T="time:',time,'",I=',(N + 1),',J=',1,',F=POINT'
        !write(*,*) 'time', time

        do i = 1, (2*N + 1) !! Write position of bubble surface to file 999
            write(999,*) r_graph(i), z_graph(i)
        enddo


    endif

    if((ll.eq.1).and.(torus_switch.eq.0).and.(teller3.eq.0).and.(mod(t,t1a).eq.0))then

        call reflect_surface(r_graph, z_graph, r, z, N)

        do i = 1, (2*N + 1) !! Write position of bubble surface to file 999
            write(1000,*) r_graph(i), z_graph(i)
        enddo


    endif



    if((ll.eq.1).and.(torus_switch.eq.0).and.(teller3.eq.0).and.(mod(t,t1b).eq.0))then

        call reflect_surface(r_graph, z_graph, r, z, N)

        do i = 1, (2*N + 1) !! Write position of bubble surface to file 999
            write(1001,*) r_graph(i), z_graph(i)
        enddo


    endif


    ! first vr phase
    if((ll.eq.1).and.(torus_switch.eq.1).and.(teller3.eq.1).and.(mod(teller,t2).eq.0))then
        call reflect_surface_torus(r_graph_aft, z_graph_aft, r_graphop, z_graphop, r, z,&
            N)

        write(9998,*) 'VARIABLES = "r", "z"'
        write(9998,*) 'ZONE T="time:',time,'",I=',(N+1),',J=',1,',F=POINT'

        do i = 1, (N + 1) !! Write position of bubble surface to file 999
            write(9999,*) r_graph_aft(i), z_graph_aft(i)
        enddo
        do i = 1, (N + 1)
            write(9999,*) r_graphop(i), z_graphop(i)
        enddo


    endif

    if((ll.eq.1).and.(torus_switch.eq.1).and.(teller3.eq.1).and.(mod(teller,t2a).eq.0))then
        call reflect_surface_torus(r_graph_aft, z_graph_aft, r_graphop, z_graphop, r, z,&
            N)

        write(9998,*) 'VARIABLES = "r", "z"'
        write(9998,*) 'ZONE T="time:',time,'",I=',(N+1),',J=',1,',F=POINT'

        do i = 1, (N + 1) !! Write position of bubble surface to file 999
            write(99991,*) r_graph_aft(i), z_graph_aft(i)
        enddo
        do i = 1, (N + 1)
            write(99991,*) r_graphop(i), z_graphop(i)
        enddo


    endif

    ! second singly connected phase
    if(teller3.eq.2)then
    if((ll.eq.1).and.(torus_switch.eq.0).and.(mod(t,t3).eq.0))then

        call reflect_surface(r_graph, z_graph, r, z, N)

        do i = 1, (2*N + 1) !! Write position of bubble surface to file 999
            write(997,*) r_graph(i), z_graph(i)
        enddo


    endif
    endif



    ! second vbr phase
    if((ll.eq.1).and.(torus_switch.eq.1).and.(teller3.eq.3).and.(mod(teller,t4).eq.0))then
        call reflect_surface_torus(r_graph_aft, z_graph_aft, r_graphop, z_graphop, r, z,&
            N)


        do i = 1, (N + 1) !! Write position of bubble surface to file 999
            write(567,*) r_graph_aft(i), z_graph_aft(i)
        enddo
        do i = 1, (N + 1)
            write(567,*) r_graphop(i), z_graphop(i)
        enddo


    endif


    if((ll.eq.1).and.(torus_switch.eq.0).and.(mod(t,50).eq.0))then
        write(711,*) time, pulsebot, pulsetop
    endif
   ! if((ll.eq.1).and.(torus_switch.eq.1).and.(mod(teller,t2).eq.0))then
   !     write(711,*) time, pulsebot, pulsetop
  !  endif
   ! if((ll.eq.1).and.(torus_switch.eq.0).and.(teller3.eq.2).and.(mod(t,t3).eq.0))then
   !     write(711,*) time, pulsebot, pulsetop
   ! endif


    RETURN

END SUBROUTINE


SUBROUTINE smoothing_var(N, rr, zz, pphi, rem_pot, vpot, ll, t, torus_switch,&
    smoothing, teller, counter, alpha, delphi, N_trap, a,&
    c, N_int, u_vortex, w_vortex, tau )
    ! Smooths bubble surface to prevent saw-tooth instabilities occuring


    INTEGER                          :: N, teller, torus_switch, counter, ll, t,&
        smoothing, N_trap, k
    DOUBLE PRECISION                 :: maximumz, alpha, delphi, a, c, delphi2
    DOUBLE PRECISION, DIMENSION(N+1) :: rr, zz, pphi, vpot, rem_pot,&
        u_vortex, w_vortex, arcint, tau

    u_vortex = u_vortex
    w_vortex = w_vortex
    arcint = arcint
    N_trap = N_trap
    N_int = N_int
    a = a
    c = c
    delphi = delphi
    k = 1

    !! Every so often perform smoothing
    if(torus_switch.eq.0)then !before collapse

        maximumz = maxval(zz)

        if(maximumz.ne.0)then

            if((mod(t,10).eq.0).and.(t.ne.0).and.(ll.eq.1))then

                call smooth_odd(rr, N) !Smooths odd variables (wrt arclength)
                call smooth_even(zz, N) !Smooths even variables (wrt arclength)
                call smooth_even(pphi, N)
              !  call smooth_even(tau,N)

            endif

        endif



    elseif(torus_switch.eq.1)then    !for toroidal bubble


        delphi2 = pphi(N+1) - pphi(1)

        if((mod(t,smoothing).eq.0).and.(t.ne.0).and.(ll.eq.1))then

           CALL vr_smooth_torus_r_z(rr, N, alpha)
           CALL vr_smooth_torus_r_z(zz, N, alpha)
           CALL vr_smooth_torus_r_z(rem_pot, N, alpha)
         !  CALL vr_smooth_torus_r_z(tau, N, alpha)
           !CALL vr_smooth_torus_phi(pphi, N, alpha, delphi2)

           !rem_pot(N+1) = rem_pot(1)

        !  CALL vortpot_n1( N,N_trap,delphi,rr,zz,a,c,vpot(1) )


       !   CALL arcint_calc2( N,N_int,N_trap,rr,zz,a,c,delphi,arcint, u_vortex, w_vortex)


       !   DO k = 2, (N+1)
       !      vpot(k) = vpot(k-1) + arcint(k)  !vpot is potential of vortex ring.
        !  ENDDO

       !   DO k = 1,(N+1)
            ! pphi(k) = rem_pot(k) + vpot(k)
        !  ENDDO

        !  CALL vr_smooth_torus_phi(pphi, N, alpha, delphi)


        endif

    !write(*,*) 'after smooth'
    !DO k=1,(N+1)
    !   write(*,*) rem_pot(k), vpot(k)
    !ENDDO

    endif

    ! Smooth at start of vortex ring bubble
    if((ll.eq.1).and.(teller.gt.0).and.(teller.lt.10))then

           CALL vr_smooth_torus_r_z(rr, N, alpha)
           CALL vr_smooth_torus_r_z(zz, N, alpha)
           CALL vr_smooth_torus_r_z(rem_pot, N, alpha)
         !  CALL vr_smooth_torus_r_z(tau, N, alpha)
         !  CALL vr_smooth_torus_phi(pphi, N, alpha, delphi2)

         !  rem_pot(N+1) = rem_pot(1)

    endif



    ! Smooth at start of reconnection
    if((ll.eq.1).and.(torus_switch.eq.0).and.(counter.gt.1).and.(counter.lt.10))then

        !call smooth_odd(rr, N) !Smooths odd variables (wrt arclength)
        !call smooth_even(zz, N) !Smooths even variables (wrt arclength)
        !call smooth_even(pphi, N)
        !call smooth_even(tau,N)

    endif


    RETURN

END SUBROUTINE


SUBROUTINE splinecalc_redist(N, r, z, phi, ar, br, cr, dr, er, az, bz, cz, dz, ez,&
    aphi, bphi, cphi, dpphi, ephi, aphir, bphir, cphir, dphir,&
    ephir, s, rem_pot, vpot, extra_stress, torus_switch, ll, t,&
    u_vortex, w_vortex, N_trap, N_int, delphi, a, c)

    INTEGER                          :: N, t, ll, torus_switch, N_trap, N_int, k
    DOUBLE  PRECISION                :: length, delphi, a, c
    DOUBLE PRECISION, DIMENSION(N+1) :: r, z, phi, rem_pot, s, ar, br, cr, dr, er,&
        az, bz, cz, dz, ez, aphi, bphi, cphi, dpphi,&
        ephi, aphir, bphir, cphir, dphir, ephir,&
        extra_stress, aTs, bTs, cTs, dTs, eTs, arcint,&
        u_vortex, w_vortex, vpot


    !*** These subroutines calculate the arclength and spline coefficients on the BUBBLE SURFACE
    call iterative_arclength_calc(r, z, ar, br, cr, dr, er, az, bz, cz, dz, ez,&
        s, length, N, torus_switch)



    !*** Calculates spline coefficients for potential (phi) on surface
    if (torus_switch.eq.0)then

        call Quintic_Clamped_parameterised_arclength(N, aphi, bphi, cphi,&
            dpphi, ephi, phi, s)
        call Quintic_Clamped_parameterised_arclength(N, aTs, bTs, cTs, dTs, eTs, extra_stress, s)

    else

        call Quintic_periodic_parameterised_arclength(N, aphir, bphir, cphir,&
            dphir, ephir, rem_pot, s)
        call Quintic_periodic_parameterised_arclength(N, aTs, bTs, cTs, dTs, eTs, extra_stress, s)

    endif


    if((ll.eq.1).and.(t.ne.0))then

        !Every time step the splines are used to redistribute nodes equally with respect
        !to arclength

        ! redistribute variables so they're equally spaced with respect to arclength
        call redistribute_new(r, ar, br, cr, dr, er, s, length, N, torus_switch)
        call redistribute_new(z, az, bz, cz, dz, ez, s, length, N, torus_switch)
        if(torus_switch.eq.0)then
            call redistribute_new(phi, aphi, bphi, cphi, dpphi, ephi, s, length, N, torus_switch)
        endif
        if(torus_switch.eq.1)then
            call redistribute_new(rem_pot, aphir, bphir, cphir, dphir, ephir, s, length, N, torus_switch)
        endif
        call redistribute_new(extra_stress, aTs, bTs, cTs, dTs, eTs, s, length, N, torus_switch)

         !After redistribution, then determine new spline coefficients for r,z, and phi

        if(torus_switch.eq.1)then

            vpot = 0d0
            arcint = 0d0

            CALL vortpot_n1( N,N_trap,delphi,r,z,a,c,vpot(1) )


            CALL arcint_calc2( N,N_int,N_trap,r,z,a,c,delphi,arcint, u_vortex, w_vortex)


            DO k = 2,(N+1)
                vpot(k) = vpot(k-1) + arcint(k)  !vpot is potential of vortex ring.
            ENDDO

            DO k= 1,(N+1)
                phi(k) = rem_pot(k) + vpot(k)
            ENDDO

        !write(*,*) 'after redist'
        !DO k=1,(N+1)
        !   write(*,*) rem_pot(k), vpot(k)
        !ENDDO
        !stop

        endif

        call iterative_arclength_calc(r, z, ar, br, cr, dr, er, az, bz, cz, dz, ez,&
                                      s, length, N, torus_switch)

        if(torus_switch.eq.0) then

            call Quintic_Clamped_parameterised_arclength(N, aphi, bphi, cphi, dpphi, ephi, phi, s)

        else

            call Quintic_periodic_parameterised_arclength(N, aphir, bphir, cphir,&
                dphir, ephir, rem_pot, s)

        endif

    endif


    RETURN

END SUBROUTINE


SUBROUTINE normal_vel_BIE(N,r,z, z_image, phi,ar,br,cr,dr,er,az,bz,cz,dz,ez,aphi,bphi,&
    cphi,dpphi,ephi,s,pi,wall_switch,HP)
    ! Uses the boundary integral equation to find dphi/dn (normal velocity at bubble surface)


    INTEGER                               :: N, i, j, wall_switch
    DOUBLE PRECISION                      :: II1, II2, III, IIIa, Gimage_int1, Gimage_int2,&
        Himage_int1, Himage_int2, pi
    DOUBLE PRECISION, DIMENSION(N+1)      :: r, z, phi, s, ar, br, cr, dr, er, az, bz,&
        cz, dz, ez, aphi, bphi, cphi, dpphi, ephi,&
        H, HP, A1, const, z_image
    DOUBLE PRECISION, DIMENSION(N+1,N+1) :: G


    G = 0d0
    H = 0d0
    const = 0d0
    A1 = 0d0
    HP = 0d0

    do 8 i = 1, (N + 1) !Loop over collocation points i (corresponds to p in formula) on bubble surface

        do 9 j = 1, N !Loop over each segement on surface (j corresponds to q)

 if((i.eq.1).or.(i.eq.(N + 1)))then
                !If collocation point i is on axis of symmetry then G and dG/dn are of a different
                !form due to a singularity. I don't think this form is give in my thesis...
                call gaussaxis(r(j), z(j), z(i),&
                    aphi(j), bphi(j), cphi(j), dpphi(j), ephi(j),&
                    ar(j), br(j), cr(j), dr(j), er(j),&
                    az(j), bz(j), cz(j), dz(j), ez(j),&
                    II1, II2, III, phi(j), IIIa, s(j + 1), s(j))


            !Else if i is on segement to be integrated over then integrals G,dG/dn have
            !logaritmic singularity on that segment (here singularity at start of segment)
            elseif(i.eq.j)then
                call loggauss1(r(j), z(j), r(i), z(i),&
                    aphi(j), bphi(j), cphi(j), dpphi(j), ephi(j),&
                    ar(j), br(j), cr(j), dr(j), er(j),&
                    az(j), bz(j), cz(j), dz(j), ez(j),&
                    II1, II2, III, phi(j), IIIa, s(j + 1), s(j))

            !If singularity at end of segment...
            !The forms of the integrals in these cases can be found in the appendix of my thesis
            elseif(i.eq.(j + 1))then
                call loggauss2(r(j), z(j), r(i), z(i),&
                    aphi(j), bphi(j), cphi(j), dpphi(j), ephi(j),&
                    ar(j), br(j), cr(j), dr(j), er(j),&
                    az(j), bz(j), cz(j), dz(j), ez(j),&
                    II1, II2, III, phi(j), IIIa, s(j + 1), s(j))


            !Else then one can calculate the standard integrals as given in thesis.
            else
                call gauss(r(j), z(j), r(i), z(i),&
                    aphi(j), bphi(j), cphi(j), dpphi(j), ephi(j),&
                    ar(j), br(j), cr(j), dr(j), er(j),&
                    az(j), bz(j), cz(j), dz(j), ez(j),&
                    II1, II2, III, phi(j), IIIa, s(j + 1), s(j))

            end if


            !Construct linear system.
            G(i, j) = G(i, j) + II1
            G(i, j + 1) = G(i, j + 1) + II2

            H(i) = H(i) + III


            A1(i) = A1(i) + IIIa        ! used to determine a more accurate value of the constant c(p)

             !If wall switch is on, then consider image bubble
            if(wall_switch.eq.1)then

                ! If image bubble on axis...
                if((i.eq.1).or.(i.eq.(N + 1)))then
                    call gaussaxis(r(j), z(j), z_image(i),&
                        aphi(j), bphi(j), cphi(j), dpphi(j), ephi(j),&
                        ar(j), br(j), cr(j), dr(j), er(j),&
                        az(j), bz(j), cz(j), dz(j), ez(j),&
                        Gimage_int1, Gimage_int2, Himage_int1, phi(j),&
                        Himage_int2, s(j + 1), s(j))

                else

                    ! Else loop over rest of surface.
                    call gauss(r(j), z(j), r(i), z_image(i),&
                        aphi(j), bphi(j), cphi(j), dpphi(j), ephi(j),&
                        ar(j), br(j), cr(j), dr(j), er(j),&
                        az(j), bz(j), cz(j), dz(j), ez(j),&
                        Gimage_int1, Gimage_int2, Himage_int1, phi(j),&
                        Himage_int2, s(j + 1), s(j))
                end if

                !Append linear system with image
                G(i, j) = G(i, j) + Gimage_int1         !store integrations along segements in matrices
                G(i, j + 1) = G(i, j + 1) + Gimage_int2     ! Matrix G holds info about dPhi/dn
                                                     ! Matrix H holds info about Phi
                H(i) = H(i) + Himage_int1

            endif


9       continue         ! --> j-loop

        !Const is constant c(p). Given the discretisation, it can be more accurately determined by this method
        !(as opposed to simply using 2pi or 4pi). See Paris and Canas [113].
        const(i) = 4d0*pi - A1(i)

        !Vector of phi integrals
        H(i) = H(i) + const(i)*phi(i)



8   continue          ! --> i-loop

    !For some reason I redefine H as HP. This probably comes from previous
    !versions of code.
    do 10  i = 1, (N + 1)

        HP(i) = H(i)

10  continue

    !Use Gaussian Elimination to solve linear system
    !Returning the normal velocity in HP(i)
    call GaussJ(G, (N + 1), HP)


    RETURN

END SUBROUTINE




SUBROUTINE VR_normal_vel_BIE(N, r, z, z_image, rem_pot, ar, br, cr, dr, er,&
    az, bz, cz, dz, ez, aphir, bphir,&
    cphir, dphir, ephir, s, pi, wall_switch, HP_rem)
    ! Uses the boundary integral equation to find dphi/dn (normal velocity at bubble surface)


    INTEGER                              :: N, i, j, wall_switch
    DOUBLE PRECISION                     :: II1, II2, III, IIIa, Gimage_int1, Gimage_int2,&
        Himage_int1, Himage_int2, pi
    DOUBLE PRECISION, DIMENSION(N+1)     :: r, z, rem_pot, s, ar, br, cr, dr, er, az, bz,&
        cz, dz, ez, aphir, bphir, cphir, dphir, ephir,&
        HP_rem, z_image
    DOUBLE PRECISION, DIMENSION(N)       :: H2, A12, const2
    DOUBLE PRECISION, DIMENSION(N,N)     :: G2


    HP2 = 0d0
    HP_rem = 0d0
    G2 = 0d0
    H2 = 0d0
    A12 = 0d0

    do 80 i = 1, (N) !Loop over collocation points i (p in formula) on bub surface
        do 90 j = 1, (N-1) !Loop over segements on surface ( q )

            !If i is on segement to be integrated over then integrals G,dG/dn have
            !logaritmic singularity on that segment (here singularity at start of segment)
            if(i.eq.j)then
                call loggauss1(r(j), z(j), r(i), z(i),&
                    aphir(j), bphir(j), cphir(j), dphir(j), ephir(j),&
                    ar(j), br(j), cr(j), dr(j), er(j),&
                    az(j), bz(j), cz(j), dz(j), ez(j),&
                    II1, II2, III, rem_pot(j), IIIa, s(j + 1), s(j))


            !If singularity at end of segment...
            !The forms of the integrals in these cases can be found in the appendix of my thesis
            elseif(i.eq.(j + 1))then
                call loggauss2(r(j), z(j), r(i), z(i),&
                    aphir(j), bphir(j), cphir(j), dphir(j), ephir(j),&
                    ar(j), br(j), cr(j), dr(j), er(j),&
                    az(j), bz(j), cz(j), dz(j), ez(j),&
                    II1, II2, III, rem_pot(j), IIIa, s(j + 1), s(j))


            !Else then one can calculate the standard integrals as given in thesis.
            else
                call gauss(r(j), z(j), r(i), z(i),&
                    aphir(j), bphir(j), cphir(j), dphir(j), ephir(j),&
                    ar(j), br(j), cr(j), dr(j), er(j),&
                    az(j), bz(j), cz(j), dz(j), ez(j),&
                    II1, II2, III, rem_pot(j), IIIa, s(j + 1), s(j))
            end if


            !Construct linear system.
            G2(i, j) = G2(i, j) + II1
            G2(i, j + 1) = G2(i, j + 1) + II2

            H2(i) = H2(i) + III

            A12(i) = A12(i) + IIIa        ! used to determine a more accurate value of the constant c(p)

             !If wall switch is on, then consider image bubble
            if(wall_switch.eq.1)then

                ! Else loop over rest of surface.
                call gauss(r(j), z(j), r(i), z_image(i),&
                    aphir(j), bphir(j), cphir(j), dphir(j), ephir(j),&
                    ar(j), br(j), cr(j), dr(j), er(j),&
                    az(j), bz(j), cz(j), dz(j), ez(j),&
                    Gimage_int1, Gimage_int2, Himage_int1, rem_pot(j),&
                    Himage_int2, s(j + 1), s(j))


                !Append linear system with image
                G2(i, j) = G2(i, j) + Gimage_int1         !store integrations along segements in matrices
                G2(i, j + 1) = G2(i, j + 1) + Gimage_int2     ! Matrix G holds info about dPhi/dn
                                                     ! Matrix H holds info about Phi
                H2(i) = H2(i) + Himage_int1

            endif


90      continue         ! --> j-loop

        j = N

        !If i is on segement to be integrated over then integrals G,dG/dn have
        !logaritmic singularity on that segment (here singularity at start of segment)
        if(i.eq.j)then
            call loggauss1(r(j), z(j), r(i), z(i),&
                aphir(j), bphir(j), cphir(j), dphir(j), ephir(j),&
                ar(j), br(j), cr(j), dr(j), er(j),&
                az(j), bz(j), cz(j), dz(j), ez(j),&
                II1, II2, III, rem_pot(j), IIIa, s(j + 1), s(j))


        !If singularity at end of segment...
        !The forms of the integrals in these cases can be found in the appendix of my thesis
        elseif(i.eq.1)then
            call loggauss2(r(j), z(j), r(i), z(i),&
                aphir(j), bphir(j), cphir(j), dphir(j), ephir(j),&
                ar(j), br(j), cr(j), dr(j), er(j),&
                az(j), bz(j), cz(j), dz(j), ez(j),&
                II1, II2, III, rem_pot(j), IIIa, s(j + 1), s(j))


        !Else then one can calculate the standard integrals as given in thesis.
        else
            call gauss(r(j), z(j), r(i), z(i),&
                aphir(j), bphir(j), cphir(j), dphir(j), ephir(j),&
                ar(j), br(j), cr(j), dr(j), er(j),&
                az(j), bz(j), cz(j), dz(j), ez(j),&
                II1, II2, III, rem_pot(j), IIIa, s(j + 1), s(j))
        end if

        !Construct linear system.
        G2(i, N) = G2(i, N) + II1
        G2(i, 1) = G2(i, 1) + II2

        H2(i) = H2(i) + III

        A12(i) = A12(i) + IIIa        ! used to determine a more accurate value of the constant c(p)

        !If wall switch is on, then consider image bubble
        if(wall_switch.eq.1)then

            ! Else loop over rest of surface.
            call gauss(r(j), z(j), r(i), z_image(i),&
                aphir(j), bphir(j), cphir(j), dphir(j), ephir(j),&
                ar(j), br(j), cr(j), dr(j), er(j),&
                az(j), bz(j), cz(j), dz(j), ez(j),&
                Gimage_int1, Gimage_int2, Himage_int1, rem_pot(j),&
                Himage_int2, s(j + 1), s(j))


            !Append linear system with image
            G2(i, j) = G2(i, j) + Gimage_int1         !store integrations along segements in matrices
            G2(i, 1) = G2(i, 1) + Gimage_int2     ! Matrix G holds info about dPhi/dn
                                                 ! Matrix H holds info about Phi
            H2(i) = H2(i) + Himage_int1

        end if


        !Const is constant c(p). Given the discretisation, it can be more accurately determined by this method
        !(as opposed to simply using 2pi or 4pi). See Paris and Canas [113].
        const2(i) = 4d0*pi - A12(i)

        !Vector of phi integrals
        H2(i) = H2(i) + const2(i)*rem_pot(i)

80  continue          ! --> i-loop



    !Use Gaussian Elimination to solve linear system
    !Returning the normal velocity in HP(i)
    call GaussJ(G2, (N), H2)

    DO i=1,N
        HP_rem(i) = H2(i)
    ENDDO


    HP_rem(N+1) = HP_rem(1)




    RETURN

END SUBROUTINE



SUBROUTINE torus_surf_derivs(N, r, z, s, rem_pot, deltaPhi,&
    phi, nr, nz, sr, sz, n_order, tang_rem,&
    tang_vel, dphi2_ds2, curvature, r_curvature, drem2_ds2,&
    HP_rem, HP, u_vortex, w_vortex)


    INTEGER                          :: N, n_order, i
    DOUBLE PRECISION                 :: deltaPhi
    DOUBLE PRECISION, DIMENSION(N+1) :: rem_pot, tang_rem,&
        HP_rem, HP, r_curvature, drem2_ds2, &
        u_vortex, w_vortex, r, z, s, nr, nz, sr, sz,&
        tang_vel, curvature, dphi2_ds2, phi, temp


    nr = 0d0
    nz = 0d0
    sr = 0d0
    sz = 0d0

    !Now the same using remnant potential, only use tangential deriv.
    call SURFACE_REM_torus(r, z, rem_pot, s, nr, nz, sr, sz,&
        N, n_order, deltaPhi, tang_rem, r_curvature, drem2_ds2, HP_rem)


    !Calculating normal deriv of phi using phi = rem_pot + vpot


    HP = 0d0

    DO i=1,(N+1)

        HP(i) = HP_rem(i) + nr(i)*u_vortex(i) + nz(i)*w_vortex(i)

    ENDDO


    !write(*,*) 'HP after'
    DO i=1,(N+1)
        tang_vel(i) = tang_rem(i) + u_vortex(i)*sr(i) + w_vortex(i)*sz(i)
        temp(i) = tang_vel(i)
        !write(*,*) '1', tang_vel(i)
    !  write(*,*) s(i), phi(i), tang_vel(i), tang_vel2(i)
    ENDDO
    !stop
    !tang_vel(1) = ( tang_vel(2) + tang_vel(N) )/2d0
    !tang_vel(N+1) = tang_vel(1)

    !deltaPhi = phi(N+1) - phi(1)

    call SURFACE_torus(r, z, phi, s, nr, nz, sr, sz,&
        N, n_order, deltaPhi, tang_vel, curvature, dphi2_ds2, HP)

        !DO i=1,(N+1)
        !    write(*,*) tang_vel(i), temp(i)
        !ENDDO


    RETURN

END SUBROUTINE


SUBROUTINE energy_routine(N, N_trap, r, z, torus_switch, deltaPhi, jet_velocity,&
    phi, HP, rem_pot, lamb, wall_switch, a, c,&
    V0, epsil, delt, total_energy, E1_app, E1, E2, E3, E4, jet_ap)


    INTEGER                          :: N, N_trap, torus_switch, wall_switch, i
    DOUBLE PRECISION                 :: vol, length, total_energy, E1, E2, E3, E4,&
        deltaPhi, jet_velocity, V0, epsil, delt,&
        lamb, E1_app, a, c, jet_ap(6)
    DOUBLE PRECISION, DIMENSION(N+1) :: r, z, phi, HP, phiHP, ar, br, cr, dr, er,&
        az, bz, cz, dz, ez, aphihp, bphihp, cphihp,&
        dphihp, ephihp, s, rem_pot


    CALL iterative_arclength_calc(r, z, ar, br, cr, dr, er, az, bz, cz, dz, ez,&
        s, length, N, torus_switch)

    call calc_vol(N, r, ar, br, cr, dr, er, az, bz, cz, dz, ez, s, vol)
    vol = -vol


    if(torus_switch.eq.0)then

        do i=1,(N+1)

            phiHP(i) = phi(i)*HP(i)

        enddo

        call Quintic_Clamped_parameterised_arclength(N, aphihp, bphihp,&
            cphihp, dphihp, ephihp, phiHP,s)


        CALL energy_calc(r, z, N, N_trap, ar, br, cr, dr, er,&
            aphihp, bphihp, cphihp, dphihp, ephihp,&
            deltaPhi, phi, rem_pot, HP, phiHP, s,&
            torus_switch, vol, V0, lamb, total_energy,&
            epsil, delt, E1, E2, E3, E4, wall_switch,&
            jet_velocity, a, c, E1_app, jet_ap)

    else

        phiHP = 0d0
        do i=1,(N+1)

            phiHP(i) = phi(i)*HP(i)

        enddo

        !write(*,*) 'phihp', phiHP

        CALL energy_calc(r, z, N, N_trap, ar, br, cr, dr, er,&
            aphihp, bphihp, cphihp, dphihp, ephihp,&
            deltaPhi, phi, rem_pot, HP, phiHP, s,&
            torus_switch, vol, V0, lamb, total_energy,&
            epsil, delt, E1, E2, E3, E4, wall_switch,&
            jet_velocity, a, c, E1_app, jet_ap)

    endif


    RETURN

END SUBROUTINE


SUBROUTINE stress_calc(N, ll, r, z, HP, tang_vel, HP_rem, tang_rem, extra_stress,&
    curvature, dphi2_ds2, nr, sr, lambda, mu, dt, dphi2_dn2,&
    torus_switch, resultant_vel, resultant_rem, radius, Rey, Deb )


    INTEGER                          :: N, i, torus_switch, ll, visco
    DOUBLE PRECISION                 :: dt, dtt, lambda, mu, Rey, Deb
    DOUBLE PRECISION, DIMENSION(N+1) :: r, z, HP, tang_vel, HP_rem, tang_rem, extra_stress,&
        extra_stress_old, curvature, dphi2_ds2, nr, sr,&
        dphi2_dn2, resultant_vel, radius,&
        resultant_rem
    visco = 0     ! 0 for material maxwell, 1 for Oldroyd-B
    Rey = Rey
    Deb = Deb

    if(visco.eq.0)then     ! MATERIAL MAXWELL FLUID

        if(torus_switch.eq.0)then
            ! For bubble surface only
            do 12 i = 1, (N + 1)

                !calculate the speed at each point.
                resultant_vel(i) = dsqrt(HP(i)**2 + tang_vel(i)**2)
                !calc radius (this is incorrect for all but spherical case centred at origin)
                radius(i) = dsqrt(r(i)**2 + z(i)**2)

                !Determine second normal derivative from forms given in thesis
                if ((i.eq.1).or.(i.eq.(N + 1)).and.(torus_switch.eq.0))then
                     !Takes different form on axis (from L'Hopital's rule) --> page 24
                    dphi2_dn2(i) = ( 2d0*dphi2_ds2(i) + 2d0*curvature(i)*HP(i) )

                else

                    dphi2_dn2(i) = ( dphi2_ds2(i) + curvature(i)*HP(i) + &
                        (1d0/r(i))*(nr(i)*HP(i)+ sr(i)*tang_vel(i)) )
                end if

                !Calculating the stress at each intermediate time step using a simple Euler scheme
                if(ll.eq.1)then
                    extra_stress_old(i) = extra_stress(i)
                elseif(ll.eq.2)then     ! backward euler approximation of Maxwell relation, with gamma dot = 2*dphi2_dn2 (page 23)
                    dtt = dt/2d0
                    extra_stress(i) = (1d0/(1d0 + lambda/dtt))*(-(mu)*2d0*dphi2_dn2(i) +&
                        (lambda/dtt)*extra_stress_old(i))
                elseif(ll.eq.3)then
                    dtt = dt/2d0
                    extra_stress(i) = (1d0/(1d0 + lambda/dtt))*(-(mu)*2d0*dphi2_dn2(i) +&
                        (lambda/dtt)*extra_stress_old(i))
                elseif(ll.eq.4)then
                    dtt = dt
                    extra_stress(i) = (1d0/(1d0 + lambda/dtt))*(-(mu)*2d0*dphi2_dn2(i) +&
                        (lambda/dtt)*extra_stress_old(i))
                elseif(ll.eq.5)then
                    dtt = dt
                    extra_stress(i) = (1d0/(1d0 + lambda/dtt))*(-(mu)*2d0*dphi2_dn2(i) +&
                        (lambda/dtt)*extra_stress_old(i))
                endif

12          continue

        else

            do 1200 i = 1, (N + 1)

                !calculate the speed at each point.
                resultant_vel(i) = dsqrt(HP(i)**2 + tang_vel(i)**2)
                resultant_rem(i) = dsqrt(HP_rem(i)**2 + tang_rem(i)**2)
                !calc radius (this is incorrect for all but spherical case centred at origin)
                radius(i) = dsqrt(r(i)**2 + z(i)**2)

                !Determine second normal derivative from forms given in thesis
                dphi2_dn2(i) = (dphi2_ds2(i) + curvature(i)*HP(i) + &
                    (1d0/r(i))*(nr(i)*HP(i)+ sr(i)*tang_vel(i)) )


                !Calculating the stress at each intermediate time step using a simple Euler scheme
                if(ll.eq.1)then
                    extra_stress_old(i) = extra_stress(i)
                elseif(ll.eq.2)then     ! backward euler approximation of Maxwell relation, with gamma dot = 2*dphi2_dn2 (page 23)
                    dtt = dt/2d0
                    extra_stress(i) = (1d0/(1d0 + lambda/dtt))*(-mu*2d0*dphi2_dn2(i) +&
                        (lambda/dtt)*extra_stress_old(i))
                elseif(ll.eq.3)then
                    dtt = dt/2d0
                    extra_stress(i) = (1d0/(1d0 + lambda/dtt))*(-mu*2d0*dphi2_dn2(i) +&
                        (lambda/dtt)*extra_stress_old(i))
                elseif(ll.eq.4)then
                    dtt = dt
                    extra_stress(i) = (1d0/(1d0 + lambda/dtt))*(-mu*2d0*dphi2_dn2(i) +&
                        (lambda/dtt)*extra_stress_old(i))
                elseif(ll.eq.5)then
                    dtt = dt
                    extra_stress(i) = (1d0/(1d0 + lambda/dtt))*(-mu*2d0*dphi2_dn2(i) +&
                        (lambda/dtt)*extra_stress_old(i))
                endif

1200        continue


        endif


    elseif(visco.eq.1)then      ! UCM or OLDROYD-B FLUID

        if(torus_switch.eq.0)then
            ! For bubble surface only
            do 1211 i = 1, (N + 1)

                !calculate the speed at each point.
                resultant_vel(i) = dsqrt(HP(i)**2 + tang_vel(i)**2)
                !calc radius (this is incorrect for all but spherical case centred at origin)
                radius(i) = dsqrt(r(i)**2 + z(i)**2)

                !Determine second normal derivative from forms given in thesis
                if ((i.eq.1).or.(i.eq.(N + 1)).and.(torus_switch.eq.0))then
                     !Takes different form on axis (from L'Hopital's rule) --> page 24
                    dphi2_dn2(i) = (2d0*dphi2_ds2(i) + 2d0*curvature(i)*HP(i))

                else

                    dphi2_dn2(i) = (dphi2_ds2(i) + curvature(i)*HP(i) + &
                        (1d0/r(i))*(nr(i)*HP(i)+ sr(i)*tang_vel(i)) )
                end if

                !Calculating the stress at each intermediate time step using a simple Euler scheme
                if(ll.eq.1)then
                    extra_stress_old(i) = extra_stress(i)
                elseif(ll.eq.2)then     ! backward euler approximation of Maxwell relation, with gamma dot = 2*dphi2_dn2 (page 23)
                    dtt = dt/2d0
                    extra_stress(i) = ( 1d0/(1d0 + lambda/dtt + 2d0*lambda*dphi2_dn2(i)) )*&
                        ( -mu*2d0*dphi2_dn2(i) + (lambda/dtt)*extra_stress_old(i) )
                elseif(ll.eq.3)then
                    dtt = dt/2d0
                    extra_stress(i) = ( 1d0/(1d0 + lambda/dtt + 2d0*lambda*dphi2_dn2(i)) )*&
                        ( -mu*2d0*dphi2_dn2(i) + (lambda/dtt)*extra_stress_old(i) )
                elseif(ll.eq.4)then
                    dtt = dt
                    extra_stress(i) = ( 1d0/(1d0 + lambda/dtt + 2d0*lambda*dphi2_dn2(i)) )*&
                        ( -mu*2d0*dphi2_dn2(i) + (lambda/dtt)*extra_stress_old(i) )
                elseif(ll.eq.5)then
                    dtt = dt
                    extra_stress(i) = ( 1d0/(1d0 + lambda/dtt + 2d0*lambda*dphi2_dn2(i)) )*&
                        ( -mu*2d0*dphi2_dn2(i) + (lambda/dtt)*extra_stress_old(i) )
                endif

1211        continue

        else

            do 1212 i = 1, (N + 1)

                !calculate the speed at each point.
                resultant_vel(i) = dsqrt(HP(i)**2 + tang_vel(i)**2)
                resultant_rem(i) = dsqrt(HP_rem(i)**2 + tang_rem(i)**2)
                !calc radius (this is incorrect for all but spherical case centred at origin)
                radius(i) = dsqrt(r(i)**2 + z(i)**2)

                !Determine second normal derivative from forms given in thesis
                dphi2_dn2(i) = (dphi2_ds2(i) + curvature(i)*HP(i) + &
                    (1d0/r(i))*(nr(i)*HP(i)+ sr(i)*tang_vel(i)) )


                !Calculating the stress at each intermediate time step using a simple Euler scheme
                if(ll.eq.1)then
                    extra_stress_old(i) = extra_stress(i)
                elseif(ll.eq.2)then     ! backward euler approximation of Maxwell relation, with gamma dot = 2*dphi2_dn2 (page 23)
                    dtt = dt/2d0
                    extra_stress(i) = ( 1d0/(1d0 + lambda/dtt + 2d0*lambda*dphi2_dn2(i)) )*&
                        ( -mu*2d0*dphi2_dn2(i) + (lambda/dtt)*extra_stress_old(i) )
                elseif(ll.eq.3)then
                    dtt = dt/2d0
                    extra_stress(i) = ( 1d0/(1d0 + lambda/dtt + 2d0*lambda*dphi2_dn2(i)) )*&
                        ( -mu*2d0*dphi2_dn2(i) + (lambda/dtt)*extra_stress_old(i) )
                elseif(ll.eq.4)then
                    dtt = dt
                    extra_stress(i) = ( 1d0/(1d0 + lambda/dtt + 2d0*lambda*dphi2_dn2(i)) )*&
                        ( -mu*2d0*dphi2_dn2(i) + (lambda/dtt)*extra_stress_old(i) )
                elseif(ll.eq.5)then
                    dtt = dt
                    extra_stress(i) = ( 1d0/(1d0 + lambda/dtt + 2d0*lambda*dphi2_dn2(i)) )*&
                        ( -mu*2d0*dphi2_dn2(i) + (lambda/dtt)*extra_stress_old(i) )
                endif

1212        continue


        endif

    endif



    RETURN

END SUBROUTINE


SUBROUTINE timestep(N, z, HP, radius, resultant_vel, extra_stress, V0,&
    vol, epsil, t_step_den, dphi, rad, av_norm_vel,&
    dt, dt_max, MAXZ )


    INTEGER                          :: N, i
    DOUBLE PRECISION                 :: V0, vol, dphi, rad, av_norm_vel, MAXZ,&
        epsil, dt, dt_max
    DOUBLE PRECISION, DIMENSION(N+1) :: z, HP, radius, resultant_vel, extra_stress,&
        abs_ex_str, t_step_den


    !determination of time step
    do i = 1, (N + 1)
        abs_ex_str(i) = dabs(extra_stress(i))
        t_step_den(i) = 1d0 + 0.5d0*resultant_vel(i)**2 + abs_ex_str(i) + epsil*(V0/vol)**(1.4)   !denominator of time step
    enddo
    !Determine the time step from maximum velocity on surface. This version also
    !includes maximum stess value on surface in determining timestep
    dphi = maxval(t_step_den)
    !dphi = vol/V0
    dt = dt_max/dphi !Time step dt
    !  dt = dt_cut*dphi
    rad = sum(radius)/(N + 1) !average radius
    av_norm_vel = sum(HP)/(N + 1)!average normal velocity

    MAXZ = minval(z) !maxval(z)



    RETURN

END SUBROUTINE


SUBROUTINE updating_surf(N, ll, r, z, phi, rem_pot, torus_switch, r_new,&
    z_new, phi_new, rem_new, r_old, z_old, phi_old, rem_pot_old, dt,&
    N_trap, deltaPhi, a, c, resultant_vel, Pinf,&
    nr, nz, sr, sz, delt, epsil, HP, tang_vel,&
    HP_rem, tang_rem, V0, vol, lamb, extra_stress, extra_stress_old, extra_stress_new, k1_r,&
    k2_r, k3_r, k4_r, k1_z, k2_z, k3_z, k4_z, k1_phi, k2_phi,&
    k3_phi, k4_phi, k1_rem, k2_rem, k3_rem, k4_rem, Webinv, K,&
    u_vortex, w_vortex, dphi2_dn2, lambda, mu, k1_t, k2_t, k3_t, k4_t, viscel, EE, &
    chi, mush, shw, inrad, radeq, PB, ppc, PP0)



    INTEGER                          :: N, ll, torus_switch, i, viscel, test
    DOUBLE PRECISION                 :: V0, vol, epsil, delt, deltaPhi, dt, a, c, lamb,&
        Webinv, lambda, mu, EE, chi, mush, shw, inrad, radeq, ppc, PP0
    DOUBLE PRECISION, DIMENSION(N+1) :: r, z, HP, resultant_vel, extra_stress, tang_rem,&
        r_new, z_new, phi_new, rem_new, tang_vel, Pinf,&
        k1_r, k1_z, k2_r, k2_z, k3_r, k3_z, k4_r,&
        k4_z, k1_phi, k1_rem, k2_phi, k2_rem, k3_phi,&
        k3_rem, k4_phi, k4_rem, r_old, z_old, phi_old,&
        rem_pot_old, vel_x_surf, vel_y_surf, u_vortex,&
        w_vortex, phi, rem_pot, nr, nz, sr, sz, HP_rem, K, PB,&
        rgrad, zgrad, tp, extra_stress_new, dphi2_dn2, k1_t, k2_t, k3_t, k4_t, extra_stress_old


if(viscel.eq.0)then
  EE = 0d0
elseif(viscel.eq.1)then
  EE = 0d0
endif

k1_t = 0d0
k2_t = 0d0
k3_t = 0d0
k4_t = 0d0

!Do i=1,(N+1)
!   Pinf(i) = PP0/ppc!1d0
!ENDDO

test = 1


    if(torus_switch.eq.0)then
    !if(test.eq.1)then
        do 13 i = 1, (N + 1)

            !Update position (r,z) and potential phi using 4th order Runge Kutta; k1 to k4 are RK4 coefficients
            !on BUBBLE SURFACE

            if(ll.eq.1) then

                k1_r(i) = (nr(i)*HP(i) + sr(i)*tang_vel(i))*dt !r update
                k1_z(i) = (nz(i)*HP(i) + sz(i)*tang_vel(i))*dt !z update
                k1_phi(i) = ( Pinf(i) - extra_stress(i) + 0.5d0*resultant_vel(i)**2 -&
                    (delt**2)*z(i) + K(i)*Webinv - &!2d0*mu*EE*dphi2_dn2(i) -&
                    (PP0/ppc + Webinv + chi)*(1d0/radeq)**(3d0*lamb) + chi*( K(i)**3d0 ) -&    ! 1d0 + Webinv + chi
                    12d0*shw*HP(i)*K(i)/( mush*( 1d0/K(i) - shw ) )     )*dt !phi update(using Bernoulli Eqn.)

              !  if(viscel.eq.1)then
              !      k1_phi(i) = (1d0 - 2d0*mu*dphi2_dn2(i) + 0.5d0*resultant_vel(i)**2 -&
              !          (delt**2)*z(i) + K(i)*Webinv - epsil*(V0/vol)**(lamb))*dt
              !  endif

                if(viscel.eq.2)then
              !      k1_t(i) = (1d0/lambda)*( -extra_stress(i) - 2d0*lambda*extra_stress(i)*dphi2_dn2(i) -&
              !                               2d0*mu*(1d0-EE)*dphi2_dn2(i) )*dt
                endif

                r_new(i) = r(i) + 0.5d0*k1_r(i)
                z_new(i) = z(i) + 0.5d0*k1_z(i)
                phi_new(i) = phi(i) + 0.5d0*k1_phi(i)
                if(viscel.eq.2)then
              !  extra_stress_new(i) = extra_stress(i) + 0.5d0*k1_t(i)
                endif

                r_old(i) = r(i)
                z_old(i) = z(i)
                phi_old(i) = phi(i)
                if(viscel.eq.2)then
              !  extra_stress_old(i) = extra_stress(i)
                endif

                vel_x_surf(i) = (nr(i)*HP(i) + sr(i)*tang_vel(i)) !velocity in r direction
                vel_y_surf(i) = (nz(i)*HP(i) + sz(i)*tang_vel(i)) !velocity in z direction


            elseif(ll.eq.2)then

                k2_r(i) = (nr(i)*HP(i) + sr(i)*tang_vel(i))*dt
                k2_z(i) = (nz(i)*HP(i) + sz(i)*tang_vel(i))*dt
                k2_phi(i) = ( Pinf(i) - extra_stress(i) + 0.5d0*resultant_vel(i)**2 -&
                    (delt**2)*z(i) + K(i)*Webinv - &!2d0*mu*EE*dphi2_dn2(i) -&
                    (PP0/ppc + Webinv + chi)*(1d0/radeq)**(3d0*lamb) + chi*( K(i)**3d0 ) -&    ! 1d0 + Webinv + chi
                    12d0*shw*HP(i)*K(i)/( mush*( 1d0/K(i) - shw ) )     )*dt !phi update(using Bernoulli Eqn.)

            !    if(viscel.eq.1)then
            !        k2_phi(i) = (1d0 - 2d0*mu*dphi2_dn2(i) + 0.5d0*resultant_vel(i)**2 -&
            !            (delt**2)*z(i) + K(i)*Webinv - epsil*(V0/vol)**(lamb))*dt
            !    endif

                if(viscel.eq.2)then
            !        k2_t(i) = (1d0/lambda)*( -extra_stress(i) - 2d0*lambda*extra_stress(i)*dphi2_dn2(i) -&
            !                                 2d0*(1d0-EE)*mu*dphi2_dn2(i) )*dt
                endif

                r_new(i) = r_old(i) + 0.5d0*k2_r(i)
                z_new(i) = z_old(i) + 0.5d0*k2_z(i)
                phi_new(i) = phi_old(i) + 0.5d0*k2_phi(i)
                if(viscel.eq.2)then
            !    extra_stress_new(i) = extra_stress_old(i) + 0.5d0*k2_t(i)
                endif

            elseif(ll.eq.3)then

                k3_r(i) = (nr(i)*HP(i) + sr(i)*tang_vel(i))*dt
                k3_z(i) = (nz(i)*HP(i) + sz(i)*tang_vel(i))*dt
                k3_phi(i) = ( Pinf(i) - extra_stress(i) + 0.5d0*resultant_vel(i)**2 -&
                    (delt**2)*z(i) + K(i)*Webinv - &!2d0*mu*EE*dphi2_dn2(i) -&
                    (PP0/ppc + Webinv + chi)*(1d0/radeq)**(3d0*lamb) + chi*( K(i)**3d0 ) -&    ! 1d0 + Webinv + chi
                    12d0*shw*HP(i)*K(i)/( mush*( 1d0/K(i) - shw ) )     )*dt !phi update(using Bernoulli Eqn.)

            !    if(viscel.eq.1)then
            !        k3_phi(i) = (1d0 - 2d0*mu*dphi2_dn2(i) + 0.5d0*resultant_vel(i)**2 -&
            !            (delt**2)*z(i) + K(i)*Webinv - epsil*(V0/vol)**(lamb))*dt
            !    endif

                if(viscel.eq.2)then
           !         k3_t(i) = (1d0/lambda)*( -extra_stress(i) - 2d0*lambda*extra_stress(i)*dphi2_dn2(i) -&
           !                                  2d0*(1d0-EE)*mu*dphi2_dn2(i) )*dt

                endif

                r_new(i) = r_old(i) + k3_r(i)
                z_new(i) = z_old(i) + k3_z(i)
                phi_new(i) = phi_old(i) + k3_phi(i)
                if(viscel.eq.2)then
          !      extra_stress_new(i) = extra_stress_old(i) + k3_t(i)
                endif

            elseif(ll.eq.4)then

                k4_r(i) = (nr(i)*HP(i) + sr(i)*tang_vel(i))*dt
                k4_z(i) = (nz(i)*HP(i) + sz(i)*tang_vel(i))*dt
                k4_phi(i) = ( Pinf(i) - extra_stress(i) + 0.5d0*resultant_vel(i)**2 -&
                    (delt**2)*z(i) + K(i)*Webinv - &!2d0*mu*EE*dphi2_dn2(i) -&
                    (PP0/ppc + Webinv + chi)*(1d0/radeq)**(3d0*lamb) + chi*( K(i)**3d0 ) -&    ! 1d0 + Webinv + chi
                    12d0*shw*HP(i)*K(i)/( mush*( 1d0/K(i) - shw ) )     )*dt !phi update(using Bernoulli Eqn.)


                PB(i) = (1d0 + Webinv + chi)*(1d0/radeq)**(3d0*lamb) + chi*( K(i)**3d0 ) &
                        + K(i)*Webinv - extra_stress(i) - 12d0*shw*HP(i)*K(i)/( mush*( 1d0/K(i) - shw ) )


            !    if(viscel.eq.1)then
            !        k4_phi(i) = (1d0 - 2d0*mu*dphi2_dn2(i) + 0.5d0*resultant_vel(i)**2 -&
            !            (delt**2)*z(i) + K(i)*Webinv - epsil*(V0/vol)**(lamb))*dt
            !    endif

                if(viscel.eq.2)then
          !          k4_t(i) = (1d0/lambda)*( -extra_stress(i) - 2d0*lambda*extra_stress(i)*dphi2_dn2(i) -&
          !                                   2d0*(1d0-EE)*mu*dphi2_dn2(i) )*dt
                endif

                !Final sum of intermediate updates for final time step update --> standard RK4 method
                r_new(i) = r_old(i) + (1d0/6d0)*(k1_r(i) + 2d0*k2_r(i) + 2d0*k3_r(i) + k4_r(i))
                z_new(i) = z_old(i) + (1d0/6d0)*(k1_z(i) + 2d0*k2_z(i) + 2d0*k3_z(i) + k4_z(i))
                phi_new(i) = phi_old(i) + (1d0/6d0)*(k1_phi(i) + 2d0*k2_phi(i) + 2d0*k3_phi(i) + k4_phi(i))

                if(viscel.eq.2)then
          !          extra_stress_new(i) = extra_stress_old(i) + (1d0/6d0)*( k1_t(i) + 2d0*k2_t(i) +&
          !              2d0*k3_t(i) + k4_t(i) )
                endif

            endif

13      continue


    else

        CALL vortex_velocity(N,N_trap,deltaPhi,r,z,a,c,u_vortex,w_vortex)

        do 103 i = 1, (N + 1)

            !Update position (r,z) and potential phi using 4th order Runge Kutta; k1 to k4 are RK4 coefficients
            !on BUBBLE SURFACE

            rgrad(i) = nr(i)*HP_rem(i) + sr(i)*tang_rem(i) + u_vortex(i)
            zgrad(i) = nz(i)*HP_rem(i) + sz(i)*tang_rem(i) + w_vortex(i)

            if(ll.eq.1) then

                k1_r(i) = rgrad(i)*dt !r update
                k1_z(i) = zgrad(i)*dt !z update
                k1_rem(i) = ( Pinf(i) - u_vortex(i)*rgrad(i) - w_vortex(i)*zgrad(i)&
                    +(1d0/2d0)*resultant_vel(i)**2d0 - extra_stress(i) + K(i)*Webinv &
                    - (delt**2)*z(i) - 2d0*mu*EE*dphi2_dn2(i) - epsil*(V0/vol)**(lamb) )*dt !rem_phi update

                !if(viscel.eq.1)then
                !k1_rem(i) = ( Pinf(i) - u_vortex(i)*rgrad(i) - w_vortex(i)*zgrad(i)&
                !    +(1d0/2d0)*resultant_vel(i)**2d0 - 2d0*mu*dphi2_dn2(i) + K(i)*Webinv &
                !    - (delt**2)*z(i) - epsil*(V0/vol)**(lamb) )*dt !rem_phi update
                !endif

                if(viscel.eq.2)then
            !        k1_t(i) = (1d0/lambda)*( -tp(i) - 2d0*lambda*tp(i)*dphi2_dn2(i) - &
           !                                  2d0*(1d0-EE)*mu*dphi2_dn2(i) )*dt
                endif

                r_new(i) = r(i) + 0.5d0*k1_r(i)
                z_new(i) = z(i) + 0.5d0*k1_z(i)
                rem_new(i) = rem_pot(i) + 0.5d0*k1_rem(i)
           !     extra_stress_new(i) = tp(i) + 0.5d0*k1_t(i)

                r_old(i) = r(i)
                z_old(i) = z(i)
                rem_pot_old(i) = rem_pot(i)
           !     extra_stress_old(i) = extra_stress(i)

                vel_x_surf(i) = (nr(i)*HP_rem(i) + sr(i)*tang_rem(i) + u_vortex(i)) !velocity in r direction
                vel_y_surf(i) = (nz(i)*HP_rem(i) + sz(i)*tang_rem(i) + w_vortex(i)) !velocity in z direction


            elseif(ll.eq.2)then

                k2_r(i) = rgrad(i)*dt
                k2_z(i) = zgrad(i)*dt
                k2_rem(i) = ( Pinf(i) - u_vortex(i)*rgrad(i) - w_vortex(i)*zgrad(i)&
                    +(1d0/2d0)*resultant_vel(i)**2d0 - extra_stress(i) + K(i)*Webinv &
                    - (delt**2)*z(i) - 2d0*mu*EE*dphi2_dn2(i) - epsil*(V0/vol)**(lamb) )*dt
               ! if(viscel.eq.1)then
               ! k2_rem(i) = ( 1d0 - u_vortex(i)*rgrad(i) - w_vortex(i)*zgrad(i)&
               !     +(1d0/2d0)*resultant_vel(i)**2d0 - 2d0*mu*dphi2_dn2(i) + K(i)*Webinv &
               !     - (delt**2)*z(i) - epsil*(V0/vol)**(lamb) )*dt !rem_phi update
               ! endif

                if(viscel.eq.2)then
       !!             k2_t(i) = (1d0/lambda)*( -tp(i) - 2d0*lambda*tp(i)*dphi2_dn2(i) -&
       !                                      2d0*(1d0-EE)*mu*dphi2_dn2(i) )*dt
                endif


                r_new(i) = r_old(i) + 0.5d0*k2_r(i)
                z_new(i) = z_old(i) + 0.5d0*k2_z(i)
                rem_new(i) = rem_pot_old(i) + 0.5d0*k2_rem(i)
       !         extra_stress_new(i) = extra_stress_old(i) + 0.5d0*k2_t(i)


            elseif(ll.eq.3)then

                k3_r(i) = rgrad(i)*dt
                k3_z(i) = zgrad(i)*dt
                k3_rem(i) = ( Pinf(i) - u_vortex(i)*rgrad(i) - w_vortex(i)*zgrad(i)&
                    +(1d0/2d0)*resultant_vel(i)**2d0 - extra_stress(i) + K(i)*Webinv &
                    - (delt**2)*z(i) - 2d0*mu*EE*dphi2_dn2(i) - epsil*(V0/vol)**(lamb) )*dt
              !  if(viscel.eq.1)then
              !  k3_rem(i) = ( 1d0 - u_vortex(i)*rgrad(i) - w_vortex(i)*zgrad(i)&
              !      +(1d0/2d0)*resultant_vel(i)**2d0 - 2d0*mu*dphi2_dn2(i) + K(i)*Webinv &
             !       - (delt**2)*z(i) - epsil*(V0/vol)**(lamb) )*dt !rem_phi update
             !   endif

                if(viscel.eq.2)then
        !            k3_t(i) = (1d0/lambda)*( -tp(i) - 2d0*lambda*tp(i)*dphi2_dn2(i) -&
        !                                     2d0*(1d0-EE)*mu*dphi2_dn2(i) )*dt
                endif

                r_new(i) = r_old(i) + k3_r(i)
                z_new(i) = z_old(i) + k3_z(i)
                rem_new(i) = rem_pot_old(i) + k3_rem(i)
       !         extra_stress_new(i) = extra_stress_old(i) + k3_t(i)


            elseif(ll.eq.4)then

                k4_r(i) = rgrad(i)*dt
                k4_z(i) = zgrad(i)*dt
                k4_rem(i) = ( Pinf(i) - u_vortex(i)*rgrad(i) - w_vortex(i)*zgrad(i)&
                    +(1d0/2d0)*resultant_vel(i)**2d0 - extra_stress(i) + K(i)*Webinv &
                    - (delt**2)*z(i) - 2d0*mu*EE*dphi2_dn2(i) - epsil*(V0/vol)**(lamb) )*dt
              !  if(viscel.eq.1)then
              !  k4_rem(i) = ( 1d0 - u_vortex(i)*rgrad(i) - w_vortex(i)*zgrad(i)&
             !       +(1d0/2d0)*resultant_vel(i)**2d0 - 2d0*mu*dphi2_dn2(i) + K(i)*Webinv &
              !      - (delt**2)*z(i) - epsil*(V0/vol)**(lamb) )*dt !rem_phi update
             !   endif

                if(viscel.eq.2)then
        !            k4_t(i) = (1d0/lambda)*( -tp(i) - 2d0*lambda*tp(i)*dphi2_dn2(i) -&
        !!                                     2d0*(1d0-EE)*mu*dphi2_dn2(i) )*dt
                endif


                !Final sum of intermediate updates for final time step update --> standard RK4 method
                r_new(i) = r_old(i) + (1d0/6d0)*(k1_r(i) + 2d0*k2_r(i) + 2d0*k3_r(i) + k4_r(i))
                z_new(i) = z_old(i) + (1d0/6d0)*(k1_z(i) + 2d0*k2_z(i) + 2d0*k3_z(i) + k4_z(i))
                rem_new(i) = rem_pot_old(i) + (1d0/6d0)*(k1_rem(i) + 2d0*k2_rem(i) + 2d0*k3_rem(i) + k4_rem(i))
                if(viscel.eq.2)then
        !            extra_stress_new(i) = extra_stress_old(i) + (1d0/6d0)*( k1_t(i) + 2d0*k2_t(i) +&
       !                 2d0*k3_t(i) + k4_t(i) )
                endif



            endif


103     continue


    endif

    RETURN

END SUBROUTINE




! Standard integration over segement j, using Gaussian quadrature.

SUBROUTINE gauss(r1, z1, ri, zi,&
    aaphi, bbphi, ccphi, ddphi, eephi,&
    aar, bbr, ccr, ddr, eer,&
    aaz, bbz, ccz, ddz, eez,&
    II1, II2, III, pphi, IIIa, s2, s1)
    implicit none
    double precision    :: II1, III, II2, gi(6), w(6), rr, zz,&
        r1, z1, zi, ri, drr, dzz, J, C, S, R, Q, P, m, K, E,&
        aar, bbr, ccr, ddr, eer, aaz, bbz, ccz, ddz, eez, &
        aaphi, bbphi, ccphi, ddphi, eephi, pphi, IIIa,&
        s2, s1, dds, ppphi, ss



    integer            :: l


    II1 = 0d0
    III = 0d0
    II2 = 0d0
    IIIa = 0d0

    !Perform Gaussian quadrature summations over l
    do 1 l = 1, 6

        gi(1)=-0.93246951420315202781
        gi(2)=-0.66120938646626451366
        gi(3)=-0.23861918608319690863     !6-gauss points
        gi(4)=0.23861918608319690863
        gi(5)=0.66120938646626451366
        gi(6)=0.93246951420315202781

        w(1)=0.17132449237917034504
        w(2)=0.36076157304813860757
        w(3)=0.46791393457269104739       !6-gauss wieghts
        w(4)=0.46791393457269104739
        w(5)=0.36076157304813860757
        w(6)=0.17132449237917034504

        dds = s2 - s1
        ss = ((s2 - s1)/2d0)*gi(l) + (s2 + s1)/2d0 !arclength function of gauss-point

        rr = aar*(ss - s1)**5 + bbr*(ss - s1)**4 + ccr*(ss - s1)**3 + &
            ddr*(ss - s1)**2 + eer*(ss - s1) + r1 ! r spline
        zz = aaz*(ss - s1)**5 + bbz*(ss - s1)**4 + ccz*(ss - s1)**3 + &
            ddz*(ss - s1)**2 + eez*(ss - s1) + z1 ! z spline
        ppphi = aaphi*(ss - s1)**5 + bbphi*(ss - s1)**4 + ccphi*(ss - s1)**3 + &
            ddphi*(ss - s1)**2 + eephi*(ss - s1) + pphi ! z spline

        drr = 5d0*aar*(ss - s1)**4 + 4d0*bbr*(ss - s1)**3 + 3d0*ccr*(ss - s1)**2 +&
            2d0*ddr*(ss - s1) + eer !r derivative
        dzz = 5d0*aaz*(ss - s1)**4 + 4d0*bbz*(ss - s1)**3 + 3d0*ccz*(ss - s1)**2 +&
            2d0*ddz*(ss - s1) + eez !r derivative

        J = dsqrt(dzz**2 + drr**2)  !Jacobian of parametric transformation
        ! Should be 1 for arclength parametrisation

        C = dsqrt((rr + ri)**2 + (zz - zi)**2)

        !Calculate values of elliptic integrals (using polynomial apprx.)
        call elliptic(rr, zz, ri, zi, m, K, E, P, Q, R, S)

        !II1 is Bij (Eqn. (2.57))
        II1 = II1 + ((s2 - ss)/dds)*(4d0*rr*J*K/C)*w(l)
        !II2 is Cij (Eqn. (2.58))
        II2 = II2 + ((ss - s1)/dds)*(4d0*rr*J*K/C)*w(l)

        !III is dG/dn (Aij in Eqn. (2.56))
        III = III - ppphi*&
            (4d0*rr/C**3)*((dzz*(rr + ri) - drr*(zz - zi)&
            - ri*dzz*(2d0/m))*(E/(1d0 - m)) + (2d0/m)*dzz*ri*K)*w(l)
        !IIIa is Aij, but without phi (for use in calculating constant c(p)
        IIIa = IIIa - (4d0*rr/C**3)*((dzz*(rr + ri) - drr*(zz - zi)&
            - ri*dzz*(2d0/m))*(E/(1d0 - m)) + (2d0/m)*dzz*ri*K)*w(l)


1   continue

    II1 = dds*0.5d0*II1 !integrals multiplied by scaling factor due to change of variables
    II2 = dds*0.5d0*II2
    IIIa = dds*0.5d0*IIIa
    III = dds*0.5d0*III

    return
END SUBROUTINE


SUBROUTINE gauss2(r1, z1, ri, zi,&
    aaphi, bbphi, ccphi, ddphi, eephi,&
    aar, bbr, ccr, ddr, eer,&
    aaz, bbz, ccz, ddz, eez,&
    phi_i, pphi, s2, s1,&
    ffff, aaff, bbff, ccff, ddff, eeff,&
    fffn, aafn, bbfn, ccfn, ddfn, eefn,&
    Aij, Bij, Cij, Dij, Eij, E2ij, Xij, Yij, ii, jj)




    integer            :: l, ii, jj

    double precision    :: gi(6), w(6), rr, zz,&
        r1, z1, zi, ri, drr, dzz, J, C, S, R, Q, P, m, K, E,&
        aar, bbr, ccr, ddr, eer, aaz, bbz, ccz, ddz, eez, &
        aaphi, bbphi, ccphi, ddphi, eephi, pphi,&
        s2, s1, dds, ppphi, ss, phi_i, ffff, aaff, &
        bbff, ccff, ddff, eeff, fspline, fffn,&
        aafn, bbfn, ccfn, ddfn, eefn, fnspline,&
        Aij, Bij, Cij, Dij, Eij, E2ij, Xij, Yij


    Aij = 0d0
    Bij = 0d0
    Cij = 0d0
    Dij = 0d0
    Eij = 0d0
    E2ij = 0d0
    Xij = 0d0
    Yij = 0d0


    gi(1)=-0.93246951420315202781
    gi(2)=-0.66120938646626451366
    gi(3)=-0.23861918608319690863     !6-gauss points
    gi(4)=0.23861918608319690863
    gi(5)=0.66120938646626451366
    gi(6)=0.93246951420315202781

    w(1)=0.17132449237917034504
    w(2)=0.36076157304813860757
    w(3)=0.46791393457269104739       !6-gauss wieghts
    w(4)=0.46791393457269104739
    w(5)=0.36076157304813860757
    w(6)=0.17132449237917034504

    !gi(1) = -0.973906528517171720
    !gi(2) = -0.865063366688984511
    !gi(3) = -0.679409568299024406
    !gi(4) = -0.433395394129247191
    !gi(5) = -0.148874338981631211
    !gi(6) = 0.148874338981631211
    !gi(7) = 0.433395394129247191
    !gi(8) = 0.679409568299024406
    !gi(9) = 0.865063366688984511
    !gi(10) = 0.973906528517171720

    !w(1) = 0.066671344308688138
    !w(2) = 0.149451349150580593
    !w(3) = 0.219086362515982044
    !w(4) = 0.269266719309996355
    !w(5) = 0.295524224714752870
    !w(6) = 0.295524224714752870
    !w(7) = 0.269266719309996355
    !w(8) = 0.219086362515982044
    !w(9) = 0.149451349150580593
    !w(10) = 0.066671344308688138


    !Perform Gaussian quadrature summations over l
    do 1 l = 1, 6

        dds = s2 - s1
        ss = ( (s2 - s1)/2d0 )*gi(l) + (s2 + s1)/2d0 !arclength function of gauss-point


        rr = aar*(ss - s1)**5 + bbr*(ss - s1)**4 + ccr*(ss - s1)**3 + &
            ddr*(ss - s1)**2 + eer*(ss - s1) + r1 ! r spline

        zz = aaz*(ss - s1)**5 + bbz*(ss - s1)**4 + ccz*(ss - s1)**3 + &
            ddz*(ss - s1)**2 + eez*(ss - s1) + z1 ! z spline

        ppphi = aaphi*(ss - s1)**5 + bbphi*(ss - s1)**4 + ccphi*(ss - s1)**3 + &
            ddphi*(ss - s1)**2 + eephi*(ss - s1) + pphi  ! phi spline - phi(i)

        fspline = aaff*(ss-s1)**5 + bbff*(ss-s1)**4 + ccff*(ss-s1)**3 + &
            ddff*(ss-s1)**2 + eeff*(ss-s1) + ffff

        fnspline = aafn*(ss-s1)**5 + bbfn*(ss-s1)**4 + ccfn*(ss-s1)**3 + &
            ddfn*(ss-s1)**2 + eefn*(ss-s1) + fffn


        drr = 5d0*aar*(ss - s1)**4 + 4d0*bbr*(ss - s1)**3 + 3d0*ccr*(ss - s1)**2 +&
            2d0*ddr*(ss - s1) + eer !r derivative
        dzz = 5d0*aaz*(ss - s1)**4 + 4d0*bbz*(ss - s1)**3 + 3d0*ccz*(ss - s1)**2 +&
            2d0*ddz*(ss - s1) + eez !r derivative

        J = dsqrt(dzz**2 + drr**2)  !Jacobian of parametric transformation
        ! Should be 1 for arclength parametrisation

        C = dsqrt((rr + ri)**2 + (zz - zi)**2)

        !Calculate values of elliptic integrals (using polynomial apprx.)
        call elliptic(rr, zz, ri, zi, m, K, E, P, Q, R, S)


        Bij = Bij + ( (s2 - ss)/dds )*(4d0*rr*J*K/C)*w(l)

        Cij = Cij + ( (ss - s1)/dds )*(4d0*rr*J*K/C)*w(l)

        Xij = Xij + ( (s2 - ss)/dds - fnspline )*(4d0*rr*J*K/C)*w(l)

        Yij = Yij + ( (ss - s1)/dds - fnspline )*(4d0*rr*J*K/C)*w(l)

        Eij = Eij + (ppphi - phi_i)*&
            (-4d0*rr/C**3)*(   (dzz*(rr + ri) - drr*(zz - zi)&
            - (ri/m)*dzz*2d0)*(E/(1d0 - m)) + 2d0*dzz*(ri/m)*K   )*w(l)

        E2ij = E2ij + &
            (-4d0*rr/C**3)*(   (dzz*(rr + ri) - drr*(zz - zi)&
            - (ri/m)*dzz*2d0)*(E/(1d0 - m)) + 2d0*dzz*(ri/m)*K   )*w(l)

        Aij = Aij + (fspline)*&
            (-4d0*rr/C**3)*(   (dzz*(rr + ri) - drr*(zz - zi)&
            - (ri/m)*dzz*2d0)*(E/(1d0 - m)) + 2d0*dzz*(ri/m)*K   )*w(l)

        Dij = Dij + (fnspline)*(4d0*rr*J*K/C)*w(l)



1   continue

    Aij = dds*0.5d0*Aij !integrals multiplied by scaling factor due to change of variables
    Bij = dds*0.5d0*Bij
    Cij = dds*0.5d0*Cij
    Dij = dds*0.5d0*Dij
    Eij = dds*0.5d0*Eij
    E2ij = dds*0.5d0*E2ij
    Xij = dds*0.5d0*Xij
    Yij = dds*0.5d0*Yij


    ! Not all integrals are needed for each entry of G so set some to zero

    if(ii.eq.jj)then
        Bij = 0d0
        Dij = 0d0
    elseif(ii.eq.(jj+1))then
        Cij = 0d0
        Dij = 0d0
    endif

    if(ii.ne.jj)then
        Xij = 0d0
    endif

    if(ii.ne.(jj+1))then
        Yij = 0d0
    endif


    return
END SUBROUTINE



!Integration when collocation point i on axis
SUBROUTINE gaussaxis(r1,z1,zi,&
    aaphi, bbphi, ccphi, ddphi, eephi,&
    aar, bbr, ccr, ddr, eer,&
    aaz, bbz, ccz, ddz, eez,&
    II1,II2,III,pphi, IIIa, s2, s1)

    implicit none
    double precision :: II1, II2, III, gi(6), w(6),&
        rr, zz, r1, z1, drr, dzz, J, C,&
        zi, pi, aar, bbr, ccr, ddr, eer, aaz, bbz, ccz, ddz, eez,&
        aaphi, bbphi, ccphi, ddphi, eephi, pphi, IIIa, s2, s1, dds, ppphi, ss

    integer          :: l


    II1 = 0d0
    IIIa  = 0d0
    II2 = 0d0
    III = 0d0

    do 1 l = 1, 6

        gi(1)=-0.93246951420315202781
        gi(2)=-0.66120938646626451366
        gi(3)=-0.23861918608319690863                      !6-gauss points
        gi(4)=0.23861918608319690863
        gi(5)=0.66120938646626451366
        gi(6)=0.93246951420315202781

        w(1)=0.17132449237917034504
        w(2)=0.36076157304813860757
        w(3)=0.46791393457269104739                       !6-gauss wieghts
        w(4)=0.46791393457269104739
        w(5)=0.36076157304813860757
        w(6)=0.17132449237917034504

        pi = 4d0*datan(1d0)

        dds = s2 - s1
        ss = ((s2 - s1)/2d0)*gi(l) + (s2 + s1)/2d0

        rr = aar*(ss - s1)**5 + bbr*(ss - s1)**4 + ccr*(ss - s1)**3 + &
            ddr*(ss - s1)**2 + eer*(ss - s1) + r1 ! r spline
        zz = aaz*(ss - s1)**5 + bbz*(ss - s1)**4 + ccz*(ss - s1)**3 + &
            ddz*(ss - s1)**2 + eez*(ss - s1) + z1 ! r spline
        ppphi = aaphi*(ss - s1)**5 + bbphi*(ss - s1)**4 + ccphi*(ss - s1)**3 + &
            ddphi*(ss - s1)**2 + eephi*(ss - s1) + pphi ! z spline

        drr = 5d0*aar*(ss - s1)**4 + 4d0*bbr*(ss - s1)**3 + 3d0*ccr*(ss - s1)**2 +&
            2d0*ddr*(ss - s1) + eer !r derivative
        dzz = 5d0*aaz*(ss - s1)**4 + 4d0*bbz*(ss - s1)**3 + 3d0*ccz*(ss - s1)**2 +&
            2d0*ddz*(ss - s1) + eez !r derivative

        J = dsqrt(dzz**2+drr**2)

        C = dsqrt((rr)**2+(zz-zi)**2)

        !II1,II2,etc.. have a different form if (ri,zi) on axis of symmetry (ie. ri=0)

        II1 = II1 + ((s2 - ss)/dds)*(2d0*pi*J*rr/C)*w(l)
        II2 = II2 + ((ss - s1)/dds)*(2d0*pi*J*rr/C)*w(l)

        III = III - ppphi*&
            (2d0*pi*rr/C**3)*(dzz*(rr) - drr*(zz - zi))*w(l)

        IIIa = IIIa - (2d0*pi*rr/C**3)*(dzz*(rr) - drr*(zz - zi))*w(l)


1   continue

    II1 = dds*0.5d0*II1
    II2 = dds*0.5d0*II2
    III = dds*0.5d0*III
    IIIa = dds*0.5d0*IIIa

    return
END SUBROUTINE


!Integrate over segment j when i is at one end of segement
SUBROUTINE loggauss1(r1, z1, ri, zi,&
    aaphi, bbphi, ccphi, ddphi, eephi,&
    aar, bbr, ccr, ddr, eer,&
    aaz, bbz, ccz, ddz, eez,&
    II1, II2, III, pphi, IIIa, s2, s1)

    implicit none
    double precision :: II1, III, II2, lg(6), lw(6), gi(6), w(6),&
        rr, zz, r1, z1, drr, dzz,&
        J, C, m, K, E, P, Q, R, S, ri, zi,&
        aar, bbr, ccr, ddr, eer, aaz, bbz, ccz, ddz, eez,&
        aaphi, bbphi, ccphi, ddphi, eephi, pphi, IIIa,&
        s2, s1, dds, ppphi, ss


    integer          :: l


    IIIa = 0d0
    II1 = 0d0
     !initialise integrals
    II2 = 0d0
    III = 0d0

    !Integrate over (reformulated) non-singular part (see appendix)
    do 1 l = 1, 6

        gi(1)=-0.93246951420315202781
        gi(2)=-0.66120938646626451366
        gi(3)=-0.23861918608319690863                      !6-gauss points
        gi(4)=0.23861918608319690863
        gi(5)=0.66120938646626451366
        gi(6)=0.93246951420315202781

        w(1)=0.17132449237917034504
        w(2)=0.36076157304813860757
        w(3)=0.46791393457269104739                       !6-gauss wieghts
        w(4)=0.46791393457269104739
        w(5)=0.36076157304813860757
        w(6)=0.17132449237917034504

        dds = s2 - s1
        ss = ((s2 - s1)/2d0)*gi(l) + (s2 + s1)/2d0

        rr = aar*(ss - s1)**5 + bbr*(ss - s1)**4 + ccr*(ss - s1)**3 + &
            ddr*(ss - s1)**2 + eer*(ss - s1) + r1 ! r spline
        zz = aaz*(ss - s1)**5 + bbz*(ss - s1)**4 + ccz*(ss - s1)**3 + &
            ddz*(ss - s1)**2 + eez*(ss - s1) + z1 ! r spline
        ppphi = aaphi*(ss - s1)**5 + bbphi*(ss - s1)**4 + ccphi*(ss - s1)**3 + &
            ddphi*(ss - s1)**2 + eephi*(ss - s1) + pphi ! z spline

        drr = 5d0*aar*(ss - s1)**4 + 4d0*bbr*(ss - s1)**3 + 3d0*ccr*(ss - s1)**2 +&
            2d0*ddr*(ss - s1) + eer !r derivative
        dzz = 5d0*aaz*(ss - s1)**4 + 4d0*bbz*(ss - s1)**3 + 3d0*ccz*(ss - s1)**2 +&
            2d0*ddz*(ss - s1) + eez !r derivative

        J = dsqrt(dzz**2 + drr**2)

        C = dsqrt((rr + ri)**2 + (zz - zi)**2)

        call elliptic(rr, zz, ri, zi, m, K, E, P, Q, R, S)

        !These forms of the integrals, which account for the log singularity, can be found in
        !the appendix of my thesis

        II1 = II1 + ((s2 - ss)/dds)*4d0*((rr/C)*(P - Q*dlog((1d0 - m)/((ss - s1)/dds)**2)))*J*w(l)*dds*0.5d0

        II2 = II2 + ((ss - s1)/dds)*4d0*((rr/C)*(P - Q*dlog((1d0 - m)/((ss - s1)/dds)**2)))*J*w(l)*dds*0.5d0

        III = III - ppphi*&
            4d0*(rr/(C**3))*(((R - S*dlog((1d0 - m)/(((ss - s1)/dds)**2)))/(1d0 - m))*&
            (dzz*(rr + ri) - drr*(zz - zi) - 2d0*dzz*(ri/m)) + &
            2d0*dzz*(ri/m)*(P - Q*dlog((1d0 - m)/(((ss - s1)/dds)**2))))*w(l)*dds*0.5d0

        IIIa = IIIa - 4d0*(rr/(C**3))*(((R - S*dlog((1d0 - m)/(((ss - s1)/dds)**2)))/(1d0 - m))*&
            (dzz*(rr + ri) - drr*(zz - zi) - 2d0*dzz*(ri/m)) + &
            2d0*dzz*(ri/m)*(P - Q*dlog((1d0 - m)/(((ss - s1)/dds)**2))))*w(l)*dds*0.5d0
1   continue

    !Integrate over singular part
    !Perform special log-gauss integrations which account for the log singularity
    !(see appendix)
    do 2 l = 1, 6

        lg(1) = 0.02163400584411694899d0
        lg(2) = 0.12958339115495079613d0
        lg(3) = 0.31402044991476550880d0
        lg(4) = 0.53865721735180214455d0
        lg(5) = 0.75691533737740285216d0
        lg(6) = 0.92266885137212023733d0

        lw(1) = 0.23876366257854756972d0
        lw(2) = 0.30828657327394679297d0
        lw(3) = 0.24531742656321038599d0
        lw(4) = 0.14200875656647668542d0
        lw(5) = 0.05545462232488629001d0
        lw(6) = 0.01016895869293227588d0



        dds = s2 - s1
        ss = (s2 - s1)*lg(l) + s1

        rr = aar*(ss - s1)**5 + bbr*(ss - s1)**4 + ccr*(ss - s1)**3 + &
            ddr*(ss - s1)**2 + eer*(ss - s1) + r1 ! r spline
        zz = aaz*(ss - s1)**5 + bbz*(ss - s1)**4 + ccz*(ss - s1)**3 + &
            ddz*(ss - s1)**2 + eez*(ss - s1) + z1 ! r spline
        ppphi = aaphi*(ss - s1)**5 + bbphi*(ss - s1)**4 + ccphi*(ss - s1)**3 + &
            ddphi*(ss - s1)**2 + eephi*(ss - s1) + pphi ! z spline

        drr = 5d0*aar*(ss - s1)**4 + 4d0*bbr*(ss - s1)**3 + 3d0*ccr*(ss - s1)**2 +&
            2d0*ddr*(ss - s1) + eer !r derivative
        dzz = 5d0*aaz*(ss - s1)**4 + 4d0*bbz*(ss - s1)**3 + 3d0*ccz*(ss - s1)**2 +&
            2d0*ddz*(ss - s1) + eez !r derivative

        J = dsqrt(dzz**2 + drr**2)

        C = dsqrt((rr + ri)**2 + (zz - zi)**2)

        call elliptic(rr, zz, ri, zi, m, K, E, P, Q, R, S)

        II1 = II1 + ((s2 - ss)/dds)*8d0*(rr/C)*Q*J*lw(l)*dds

        II2 = II2 + ((ss - s1)/dds)*8d0*(rr/C)*Q*J*lw(l)*dds


        III = III - ppphi*&
            8d0*(rr/C**3)*((S/(1d0 - m))*(dzz*(rr + ri) - drr*(zz - zi) - 2d0*dzz*(ri/m))&
            + 2d0*dzz*(ri/m)*Q)*lw(l)*dds

        IIIa = IIIa - 8d0*(rr/C**3)*((S/(1d0 - m))*(dzz*(rr + ri) - drr*(zz - zi) - 2d0*dzz*(ri/m))&
            + 2d0*dzz*(ri/m)*Q)*lw(l)*dds

2   continue

    II1 =  II1
    II2 =  II2
    III = -III
    IIIa = -IIIa

    return
END SUBROUTINE


!loggauss2 is the same as loggauss1 but now the singularity is at other end of segement j
SUBROUTINE loggauss2(r1, z1, ri, zi,&
    aaphi, bbphi, ccphi, ddphi, eephi,&
    aar, bbr, ccr, ddr, eer,&
    aaz, bbz, ccz, ddz, eez,&
    II1, II2, III, pphi, IIIa, s2, s1)

    implicit none
    double precision :: II1, III, II2, lg(6), lw(6), gi(6), w(6),&
        rr, zz, r1, z1, drr, dzz,&
        J, C, m, K, E, P, Q, R, S, ri, zi,&
        aar, bbr, ccr, ddr, eer, aaz, bbz, ccz, ddz, eez,&
        aaphi, bbphi, ccphi, ddphi, eephi, pphi, IIIa,&
        s2, s1, dds, ppphi, ss


    integer          :: l

    ! --> integral is separated to two integrals, one singular and one non-singular that have to be added

    !initialise integrands
    II1 = 0d0
    II2 = 0d0
    III = 0d0
    IIIa = 0d0

    !Integrate over non-singular part (see appendix)
    do 1 l = 1, 6

        gi(1)=-0.93246951420315202781
        gi(2)=-0.66120938646626451366
        gi(3)=-0.23861918608319690863                      !6-gauss points
        gi(4)=0.23861918608319690863
        gi(5)=0.66120938646626451366
        gi(6)=0.93246951420315202781

        w(1)=0.17132449237917034504
        w(2)=0.36076157304813860757
        w(3)=0.46791393457269104739                       !6-gauss wieghts
        w(4)=0.46791393457269104739
        w(5)=0.36076157304813860757
        w(6)=0.17132449237917034504

        dds = s2 - s1
        ss = ((s2 - s1)/2d0)*gi(l) + (s2 + s1)/2d0

        rr = aar*(ss - s1)**5 + bbr*(ss - s1)**4 + ccr*(ss - s1)**3 + &
            ddr*(ss - s1)**2 + eer*(ss - s1) + r1 ! r spline
        zz = aaz*(ss - s1)**5 + bbz*(ss - s1)**4 + ccz*(ss - s1)**3 + &
            ddz*(ss - s1)**2 + eez*(ss - s1) + z1 ! r spline
        ppphi = aaphi*(ss - s1)**5 + bbphi*(ss - s1)**4 + ccphi*(ss - s1)**3 + &
            ddphi*(ss - s1)**2 + eephi*(ss - s1) + pphi ! z spline

        drr = 5d0*aar*(ss - s1)**4 + 4d0*bbr*(ss - s1)**3 + 3d0*ccr*(ss - s1)**2 +&
            2d0*ddr*(ss - s1) + eer !r derivative
        dzz = 5d0*aaz*(ss - s1)**4 + 4d0*bbz*(ss - s1)**3 + 3d0*ccz*(ss - s1)**2 +&
            2d0*ddz*(ss - s1) + eez !r derivative

        J = dsqrt(dzz**2 + drr**2)

        C = dsqrt((rr + ri)**2 + (zz - zi)**2)

        call elliptic(rr, zz, ri, zi, m, K, E, P, Q, R, S)

        II1 = II1 + ((s2 - ss)/dds)*4d0*(rr/C)*(P - Q*dlog((1d0 - m)/((s2 - ss)/dds)**2))*J*w(l)*dds*0.5d0

        II2 = II2 + ((ss - s1)/dds)*4d0*(rr/C)*(P - Q*dlog((1d0 - m)/((s2 - ss)/dds)**2))*J*w(l)*dds*0.5d0

        III = III - ppphi*&
            4d0*(rr/C**3)*((((R - S*dlog((1d0 - m)/((s2 - ss)/dds)**2))/(1d0 - m))*(dzz*(rr + ri)&
            - drr*(zz - zi) - 2d0*dzz*(ri/m)) + 2d0*dzz*(ri/m)*(P - Q*dlog((1d0 - m)/((s2 - ss)/dds)**2))))&
            *w(l)*dds*0.5d0

        IIIa = IIIa - 4d0*(rr/C**3)*((((R - S*dlog((1d0 - m)/((s2 - ss)/dds)**2))/(1d0 - m))*(dzz*(rr + ri)&
            - drr*(zz - zi) - 2d0*dzz*(ri/m)) + 2d0*dzz*(ri/m)*(P - Q*dlog((1d0 - m)/((s2 - ss)/dds)**2))))&
            *w(l)*dds*0.5d0

1   continue

    !Integrate over singular part (see appendix)
    do 2 l = 1, 6

        lg(1) = 0.02163400584411694899d0
        lg(2) = 0.12958339115495079613d0
        lg(3) = 0.31402044991476550880d0                  !%6 log-gauss points
        lg(4) = 0.53865721735180214455d0
        lg(5) = 0.75691533737740285216d0
        lg(6) = 0.92266885137212023733d0

        lw(1) = 0.23876366257854756972d0
        lw(2) = 0.30828657327394679297d0
        lw(3) = 0.24531742656321038599d0      !%6 log-gauss wieghts
        lw(4) = 0.14200875656647668542d0
        lw(5) = 0.05545462232488629001d0
        lw(6) = 0.01016895869293227588d0


        !! eta = 1d0 - lg(l)


        !! ss = (s2 - s1)*(1d0 - lg(l)) + s1
        !! ds = s1 - s2

        dds = s2 - s1
        ss = -lg(l)*dds + s2

        rr = aar*(ss - s1)**5 + bbr*(ss - s1)**4 + ccr*(ss - s1)**3 + &
            ddr*(ss - s1)**2 + eer*(ss - s1) + r1 ! r spline
        zz = aaz*(ss - s1)**5 + bbz*(ss - s1)**4 + ccz*(ss - s1)**3 + &
            ddz*(ss - s1)**2 + eez*(ss - s1) + z1 ! r spline
        ppphi = aaphi*(ss - s1)**5 + bbphi*(ss - s1)**4 + ccphi*(ss - s1)**3 + &
            ddphi*(ss - s1)**2 + eephi*(ss - s1) + pphi ! z spline

        drr = 5d0*aar*(ss - s1)**4 + 4d0*bbr*(ss - s1)**3 + 3d0*ccr*(ss - s1)**2 +&
            2d0*ddr*(ss - s1) + eer !r derivative
        dzz = 5d0*aaz*(ss - s1)**4 + 4d0*bbz*(ss - s1)**3 + 3d0*ccz*(ss - s1)**2 +&
            2d0*ddz*(ss - s1) + eez !r derivative

        J = dsqrt(dzz**2 + drr**2)

        C = dsqrt((rr + ri)**2 + (zz - zi)**2)

        call elliptic(rr, zz, ri, zi, m, K, E, P, Q, R, S)


        II1 = II1 + ((s2 - ss)/dds)*8d0*(rr/C)*Q*J*lw(l)*dds
        II2 = II2 + ((ss - s1)/dds)*8d0*(rr/C)*Q*J*lw(l)*dds

        III = III - ppphi*&
            8d0*(rr/C**3)*((S/(1d0 - m))*(dzz*(rr + ri) - drr*(zz - zi)- 2d0*dzz*(ri/m))&
            + 2d0*dzz*(ri/m)*Q)*lw(l)*dds

        IIIa = IIIa - 8d0*(rr/C**3)*((S/(1d0 - m))*(dzz*(rr + ri) - drr*(zz - zi)- 2d0*dzz*(ri/m))&
            + 2d0*dzz*(ri/m)*Q)*lw(l)*dds

2   continue

    II1 =  II1
    II2 =  II2
    III =  -III
    IIIa =  -IIIa

    return
END SUBROUTINE


! Calculates elliptic integral polynomial apprxoimations
subroutine elliptic(rrr, zzz, rri, zzi, mm, KK, EE, PP, QQ, RR, SS)

    implicit none
    double precision  :: aa(5), bb(5), cc(4), dd(4), mm, m1, &
        rrr, zzz, rri, zzi, KK, EE, PP, QQ, &
        RR, SS

    !Constants for polynomials (from Abram..&Steg..)
    aa(1)=1.38629436112d0
    aa(2)=0.09666344259d0
    aa(3)=0.03590092383d0
    aa(4)=0.03742563713d0
    aa(5)=0.01451196212d0

    bb(1)=0.5d0
    bb(2)=0.12498593597d0
    bb(3)=0.06880248576d0
    bb(4)=0.03328355346d0
    bb(5)=0.00441787012d0

    cc(1)=0.44325141463d0
    cc(2)=0.06260601220d0
    cc(3)=0.04757383546d0
    cc(4)=0.01736506451d0

    dd(1)=0.24998368310d0
    dd(2)=0.09200180037d0
    dd(3)=0.04069697526d0
    dd(4)=0.00526449639d0


    mm = 4d0*rrr*rri/((rrr + rri)**2 + (zzz - zzi)**2)

    m1 = 1d0 - mm

    PP = aa(1) + aa(2)*m1 + aa(3)*m1**2 + aa(4)*m1**3 + aa(5)*m1**4
    QQ = bb(1) + bb(2)*m1 + bb(3)*m1**2 + bb(4)*m1**3 + bb(5)*m1**4

    KK = PP + QQ*dlog(1d0/m1) !Elliptic integral K

    RR = 1d0 + cc(1)*m1 + cc(2)*m1**2 + cc(3)*m1**3 + cc(4)*m1**4
    SS = dd(1)*m1 + dd(2)*m1**2 + dd(3)*m1**3 + dd(4)*m1**4

    EE = RR + SS*dlog(1d0/m1) !Elliptic integral E

    return
end subroutine elliptic

!*** THIS ROUNTINE IS OLD AND IS NOT USED ***
SUBROUTINE SLNPD(A, B, N)

    !SOLUTION OF SYSTEM OF EQUATIONS BY GAUSS ELIMINATION METHOD
    !A: SYSTEM MATRIX
    !B:ORIGINALLY CONTAINS INDEPENDENT COEEFICIENTS. AFTER SOLUTION
    !CONTAINS SYSTEM UNKNOWNS
    !N: ACUTAL NUMBER OF UNKNOWNA
    !NX: ROW AND COLUMN DIMENSIONS OF A
    integer N, n1, k, j, k1, l, i
    double precision A(N,N),B(N),D,c

    !DIMENSION A(NX,NX),B(NX)
    N1=N-1
    DO 100 K=1,N1
        K1=K+1
        C=A(K,K)
        IF(ABS(C)-1d-7)1,1,3
        1 DO 7 J=K1,N
            ! TRY TO INTERCHANGE ROWS TO GET NON ZERO DIAGONAL COEFICENT
            IF(ABS(A(J,K))-1d-7)7,7,5
            5 DO 6 L=K,N
                C=A(K,L)
                A(K,L)=A(J,L)
                A(J,L)=C
6           CONTINUE
            C=B(K)
            B(K)=B(J)
            B(J)=C
            C=A(K,K)
            GO TO 3
7       CONTINUE
        !DIVIDE ROW BY DIAGONAL COEFFICIENT
3       C=A(K,K)
        DO 4 J=K1,N
            A(K,J)=A(K,J)/C
4       CONTINUE
        B(K)=B(K)/C

        !ELIMINATE UNKNOWN X(K) FROM ROW I

        DO 10 I=K1,N
            C=A(I,K)
            DO 9 J=K1,N
                A(I,J)=A(I,J)-C*A(K,J)
9           CONTINUE
            B(I)=B(I)-C*B(K)
10      CONTINUE
100 CONTINUE

    !COMPUTE LAST UNKNOWN

    B(N)=B(N)/A(N,N)

    DO 200 L=1,N1
        K=N-L
        K1=K+1
        DO 201 J=K1,N
            B(K)=B(K)-A(K,J)*B(J)
201     CONTINUE
200 CONTINUE

    !COMPUTE VALUE OF DETERMINANT

    D=1d0
    DO 250 I=1,N
        D=D*A(I,I)
250 CONTINUE
    RETURN
END

!Calculates a natural spline with parametrisation [0,1] over each segment
!(See appendix)
subroutine spline(nn, x, a, b, c)
    implicit none


    integer                                    :: i, nn
    double precision, dimension(nn + 1)        :: b, a, c, x
    double precision, dimension(nn - 1)        :: am, bm, cm, bb, uu



    b(1) = 0d0
    b(nn + 1) = 0d0

    do i = 2, nn

        b(i) = x(i + 1) - 2d0*x(i) + x(i - 1) !RHS of linear system
        b(i) = 3d0*b(i)

    enddo

    do i = 1, (nn - 1)


        bb(i) = b(i + 1)

        am(i) = 1d0
        bm(i) = 4d0 ! Construct tri-diagonal system linear system
        cm(i) = 1d0

    enddo

    am(1) = 0d0
    cm(nn - 1) = 0d0

    ! Solve tridiag sytem using Thomas algorithm
    call tridiag(nn - 1, am, bm, cm, bb, uu)

    do i = 2, nn
        b(i) = uu(i - 1) !Found spline coefficient b
    enddo


    do i = 1, nn
        a(i) = (b(i + 1) - b(i))/3d0 !Calculate remaining coefficients
        c(i) = x(i + 1) - x(i) - a(i) - b(i)
    enddo

end subroutine spline

!Solves tri-diagonal linear system (from Numerical Recipes in Fortran)
subroutine tridiag(n, x, y, z, s, u)

    implicit none
    integer             :: j, n
    double precision    :: x(n), y(n), z(n), s(n), u(n), gam(n), bet

    bet = y(1)

    u(1) = s(1)/bet

    do j = 2, n

        gam(j) = z(j - 1)/bet
        bet = y(j) - x(j)*gam(j)
        if (bet.eq.0d0)then
            write(*,*) 'tridiag routine problem'
            stop
        endif
        u(j) = (s(j) - x(j)*u(j - 1))/bet
    enddo

    do j = (n - 1), 1, -1
        u(j) = u(j) - gam(j + 1)*u(j + 1)
    enddo


    return
end subroutine tridiag

 !This routine uses splines to calculate the length of a segement j
 !(used to determine total arclength)
SUBROUTINE segment_integrate(aar, bbr, ccr, ddr, eer, aaz, bbz, ccz, ddz, eez, I_seg)
    implicit none
    double precision  :: aar, bbr, ccr, ddr, eer, aaz, bbz, ccz, ddz, eez, gi(10), w(10), &
        r_prime, z_prime, eta, I_seg, J

    integer           :: l

    I_seg = 0d0

    gi(1) = 0.97390652851717172008d0
    gi(2) = 0.86506336668898451073d0
    gi(3) = 0.67940956829902440623d0
    gi(4) = 0.43339539412924719080d0
    gi(5) = 0.14887433898163121089d0
    gi(6) = -gi(5)                      !ordinary 10 point gauss points/weights
    gi(7) = -gi(4)
    gi(8) = -gi(3)
    gi(9) = -gi(2)
    gi(10) = -gi(1)

    w(1) = 0.06667134430868813759d0
    w(2) = 0.14945134915058059315d0
    w(3) = 0.21908636251598204400d0
    w(4) = 0.26926671930999635509d0
    w(5) = 0.29552422471475287017d0
    w(6) = w(5)
    w(7) = w(4)
    w(8) = w(3)
    w(9) = w(2)
    w(10) = w(1)

    do 1 l = 1, 10

        eta = 0.5d0*(gi(l) + 1d0)

        r_prime = 5d0*aar*eta**4 + 4d0*bbr*eta**3 + 3d0*ccr*eta**2 + 2d0*ddr*eta + eer
        z_prime = 5d0*aaz*eta**4 + 4d0*bbz*eta**3 + 3d0*ccz*eta**2 + 2d0*ddz*eta + eez

        J = dsqrt(r_prime**2 + z_prime**2) !Jacobian

        I_seg = I_seg + J*w(l)*0.5d0

1   continue
    !I_seg: length of segment j
    return
END SUBROUTINE

SUBROUTINE segment_integrate_arc(aar, bbr, ccr, ddr, eer, aaz, bbz, ccz, ddz, eez, s2, s1, I_seg)
    implicit none
    double precision  :: aar, bbr, ccr, ddr, eer, aaz, bbz, ccz, ddz, eez, gi(10), w(10), &
        r_prime, z_prime, eta, I_seg, J, s2, s1, ds

    integer           :: l

    I_seg = 0d0

    ds = (s2 - s1)

    gi(1) = 0.97390652851717172008d0
    gi(2) = 0.86506336668898451073d0
    gi(3) = 0.67940956829902440623d0
    gi(4) = 0.43339539412924719080d0
    gi(5) = 0.14887433898163121089d0
    gi(6) = -gi(5)                      !ordinary 10 point gauss points/wieghts
    gi(7) = -gi(4)
    gi(8) = -gi(3)
    gi(9) = -gi(2)
    gi(10) = -gi(1)

    w(1) = 0.06667134430868813759d0
    w(2) = 0.14945134915058059315d0
    w(3) = 0.21908636251598204400d0
    w(4) = 0.26926671930999635509d0
    w(5) = 0.29552422471475287017d0
    w(6) = w(5)
    w(7) = w(4)
    w(8) = w(3)
    w(9) = w(2)
    w(10) = w(1)

    do 1 l = 1, 10


        eta = 0.5d0*(gi(l) + 1d0)

        r_prime = 5d0*aar*(ds*eta)**4 + 4d0*bbr*(ds*eta)**3d0 + 3d0*ccr*(ds*eta)**2d0 + &
            2d0*ddr*(ds*eta) + eer
        z_prime = 5d0*aaz*(ds*eta)**4 + 4d0*bbz*(ds*eta)**3d0 + 3d0*ccz*(ds*eta)**2d0 + &
            2d0*ddz*(ds*eta) + eez

        J = dsqrt(r_prime**2 + z_prime**2)

        I_seg = I_seg + J*w(l)*0.5d0*ds      !length of segment

1   continue

    return
END SUBROUTINE


!Constructs natural cubic spline, but parametrised wrt arclength s
!(see appendix)
subroutine cubic_spline_parametrised_wrt_arclength(N, ap, bp, cp, p, s)
    implicit none


    integer            :: i, N
    double precision            :: s(N + 1), ap(N + 1), bp(N + 1), cp(N + 1),&
        Ma(N - 1), Mb(N - 1), Mc(N - 1), ds(N), dp(N - 1),&
        p(N + 1), dpsol(N - 1)


    ap = 0d0
    bp = 0d0
    cp = 0d0

    do 1 i = 1, N
        ds(i) = s(i + 1) - s(i) !length of segment i
1   continue

    do 2 i = 1, (N - 1)

        Mb(i) = 2d0*(ds(i) + ds(i + 1))
        if (i.ge.2) then
            Ma(i) = ds(i) !Construct linear system (LHS)
        end if
        if (i.lt.(N - 1))then
            Mc(i) = ds(i + 1)
        end if

        dp(i) = 3d0*((p(i + 2) - p(i + 1))/ds(i + 1) - (p(i + 1) - p(i))/ds(i))!RHS

2   continue

    !Solve linear system using Thomas Alg.
    call tridiag(N - 1, Ma, Mb, Mc, dp, dpsol)

    bp(1) = 0d0

    do 3 i = 2, N
        bp(i) = dpsol(i - 1) !Set spline b coeff.
3   continue

    do 4 i = 1, (N - 1)

        ap(i) = (bp(i + 1) - bp(i))/(3d0*ds(i)) !Calc. remaining coefficients
        cp(i) = (p(i + 1) - p(i))/ds(i) - (ds(i)/3d0)*(bp(i + 1) + 2d0*bp(i))

4   continue

    ap(N) = - bp(N)/(3d0*ds(N)) !Calc. coefficients on last segment.
    cp(N) = (p(N + 1) - p(N))/ds(N) - (ds(N)/3d0)*2d0*bp(N)

    return
end subroutine

!Calculates normal/tangent vectors, curvature, and tangential derivates using a
!finite difference scheme
subroutine SURFACE(rr, zz, pphi, ss, nnr,  nnz, ssr, ssz, nnp, nn_order,&
    ttang_vel, ccurvature, ddphi2_ds2, ddphi_dn, ddphi2_dsdn)

    implicit none
    integer          :: nnp, i, nn_order, m, nn_end

    double precision :: rr(nnp + 1), zz(nnp + 1), pphi(nnp + 1),&
        nnr(nnp + 1), nnz(nnp + 1), ssr(nnp + 1), ssz(nnp + 1),&
        dr(nnp + 1), dz(nnp + 1), dr2(nnp + 1), dz2(nnp + 1),&
        ddphi2_ds2(nnp + 1), ccurvature(nnp + 1), ttang_vel(nnp + 1), JJ,&
        ddphi_dn(nnp + 1), ddphi2_dsdn(nnp + 1),&
        ss(nnp + 1), pphi_end(nnp + 1 + nn_order),&
        rr_end(nnp + 1 + nn_order), zz_end(nnp + 1 + nn_order), ss_end(nnp + 1 + nn_order)

    !nn_order is order of scheme (has to be even)

    ddphi_dn = ddphi_dn
    ddphi2_dsdn = ddphi2_dsdn
    m = nn_order/2
    nn_end = nnp + nn_order

    do 10 i = 1, (nnp + 1)

        pphi_end(m + i) = pphi(i)
        rr_end(m + i) = rr(i)
        zz_end(m + i) = zz(i)
        ss_end(m + i) = ss(i)

10  continue

    ! This loop extends variables r,z,phi,s into negative plane so derivative can be
    ! taken on and near the axis of symmetry

    do 11 i = 1, m
        pphi_end(i) = pphi(1 + m - (i - 1))
        zz_end(i) = zz(1 + m - (i - 1))
        rr_end(i) = -rr(1 + m - (i - 1))
        ss_end(i) = -ss(1 + m - (i - 1))

        pphi_end(nnp + 1 + m + i) = pphi(nnp + 1 - i)
        zz_end(nnp + 1 + m + i) = zz(nnp + 1 - i)
        rr_end(nnp + 1 + m + i) = -rr(nnp + 1 - i)
        ss_end(nnp + 1 + m + i) = ss(nnp + 1) + (ss(nnp + 1) - ss(nnp - (i - 1)))

11  continue

    !Calc. first derivative of phi to give tang. velocity
    call first_deriv(ss_end, pphi_end, ttang_vel, nn_end, nn_order)
    !Calc. second derivative of phi ..
    call second_deriv(ss_end, pphi_end, ddphi2_ds2, nn_end, nn_order)

    !Calc. first deriv of r, dr
    call first_deriv(ss_end, rr_end, dr, nn_end, nn_order)
    !Calc. second deriv of r, dr2
    call second_deriv(ss_end, rr_end, dr2, nn_end, nn_order)

    !Calc. first deriv of z, dz
    call first_deriv(ss_end, zz_end, dz, nn_end, nn_order)
    !Calc. second deriv of z, dz2
    call second_deriv(ss_end, zz_end, dz2, nn_end, nn_order)

    do 1 i = 1, (nnp + 1)
           !Calc. in-plane curvature
        ccurvature(i) =  -(dr(i)*dz2(i) - dr2(i)*dz(i))/((dr(i)**2 + dz(i)**2)**(3d0/2d0))
        ! Calc. Jacobian
        JJ = dsqrt(dz(i)**2 + dr(i)**2)
        ! Calc. normal and tangential vectors
        nnr(i) =   (1d0/JJ)*dz(i)
        nnz(i) = - (1d0/JJ)*dr(i)
        ssr(i) =   (1d0/JJ)*dr(i)
        ssz(i) =   (1d0/JJ)*dz(i)

1   continue

    return
end subroutine

!Calculates normal/tangent vectors, curvature, and tangential derivates using the cubic splines
subroutine SURFACE_SPLINE(ss, nnr, nnz, ssr, ssz, nnp,&
    aar, bbr, ccr, ddr, eer, aaz, bbz, ccz, ddz, eez, aaphi, bbphi, ccphi, ddphi, eephi,&
    ttang_vel, ccurvature, ddphi2_ds2)

    implicit none
    integer          :: nnp, i

    double precision :: nnr(nnp + 1), nnz(nnp + 1), ssr(nnp + 1), ssz(nnp + 1),&
        dr(nnp + 1), dz(nnp + 1), dr2(nnp + 1), dz2(nnp + 1),&
        ddphi2_ds2(nnp + 1), ccurvature(nnp + 1), ttang_vel(nnp + 1), JJ,&
        ss(nnp + 1), ds,&
        aar(nnp + 1), bbr(nnp + 1), ccr(nnp + 1), ddr(nnp + 1), eer(nnp + 1),&
        aaz(nnp + 1), bbz(nnp + 1), ccz(nnp + 1), ddz(nnp + 1), eez(nnp + 1),&
        aaphi(nnp + 1), bbphi(nnp + 1), ccphi(nnp + 1), ddphi(nnp + 1), eephi(nnp + 1)


    do i = 1, nnp

        dr(i) = eer(i) !First deriv. r
        dr2(i) = 2d0*ddr(i) !Second deriv r

        dz(i) = eez(i) !First deriv. z
        dz2(i) = 2d0*ddz(i) !Second deriv z

        ttang_vel(i) = eephi(i) !First deriv. phi
        ddphi2_ds2(i) = 2d0*ddphi(i) !Second deriv. phi

    enddo

    !! for i = np + 1
    !! The same derivatives but at the last node (np+1)

    ds = ss(nnp + 1) - ss(nnp)

    dr(nnp + 1) = 5d0*aar(nnp)*(ds**4d0) + 4d0*bbr(nnp)*(ds**3d0) + 3d0*ccr(nnp)*(ds**2d0) + 2d0*ddr(nnp)*ds + eer(nnp)
    dr2(nnp + 1) = 20d0*aar(nnp)*(ds**3d0) + 12d0*bbr(nnp)*(ds**2d0) + 6d0*ccr(nnp)*ds + 2d0*ddr(nnp)

    dz(nnp + 1) = 5d0*aaz(nnp)*(ds**4d0) + 4d0*bbz(nnp)*(ds**3d0) + 3d0*ccz(nnp)*(ds**2d0) + 2d0*ddz(nnp)*ds + eez(nnp)
    dz2(nnp + 1) = 20d0*aaz(nnp)*(ds**3d0) + 12d0*bbz(nnp)*(ds**2d0) + 6d0*ccz(nnp)*ds + 2d0*ddz(nnp)

    ttang_vel(nnp + 1) = 5d0*aaphi(nnp)*(ds**4d0) + 4d0*bbphi(nnp)*(ds**3d0) + 3d0*ccphi(nnp)*(ds**2d0) +&
        2d0*ddphi(nnp)*ds + eephi(nnp)
    ddphi2_ds2(nnp + 1) = 20d0*aaphi(nnp)*(ds**3d0) + 12d0*bbphi(nnp)*(ds**2d0) + 6d0*ccphi(nnp)*ds + 2d0*ddphi(nnp)

    !Calculate in-plane curvatures and normal/tangent vectors
    do 1 i = 1, (nnp + 1)

        ccurvature(i) =  -(dr(i)*dz2(i) - dr2(i)*dz(i))/((dr(i)**2 + dz(i)**2)**(3d0/2d0))

        JJ = dsqrt(dz(i)**2 + dr(i)**2)

        nnr(i) =   (1d0/JJ)*dz(i)
        nnz(i) = - (1d0/JJ)*dr(i)
        ssr(i) =   (1d0/JJ)*dr(i)
        ssz(i) =   (1d0/JJ)*dz(i)

1   continue

    return
end subroutine

!Calcs. spline coefficients for a clamped spline with parametrisation [0,1] over each segment
subroutine clamped_spline(nn, x, a, b, c)
    implicit none

    integer                                    :: i, nn
    double precision, dimension(nn + 1)        :: b, a, c, x, am, bm, cm, uu

    do 1 i = 1, (nn + 1)

        if(i == 1)then
            b(i) = x(i + 1) - x(i)
            b(i) = 3d0*b(i)
        elseif(i == (nn + 1))then !Calc. right hand side of linear system (RHS)
            b(i) = x(i - 1) - x(i)
            b(i) = 3d0*b(i)
        else
            b(i) = x(i + 1) - 2d0*x(i) + x(i - 1)
            b(i) = 3d0*b(i)
        endif

1   continue

    do 2 i = 1, (nn + 1)

        if(i == 1)then
            bm(i) = 2d0
            cm(i) = 1d0
        elseif(i == (nn + 1))then
            am(i) = 1d0
            bm(i) = 2d0 !Construct linear system (LHS)
        else
            am(i) = 1d0
            bm(i) = 4d0
            cm(i) = 1d0
        endif
2   continue

    !Solve linear system using Thomas Alg.
    call tridiag((nn + 1), am, bm, cm, b, uu)

    do 3 i = 1, (nn + 1)
        b(i) = uu(i) !Set b spline coefficients
3   continue


    do 4 i = 1, nn

        a(i) = (b(i + 1) - b(i))/3d0 !Calc. remaining coefficients
        c(i) = x(i + 1) - x(i) - a(i) - b(i)

4   continue

    c(nn + 1) = 3d0*a(nn) + 2d0*b(nn) + c(nn)

    return
end subroutine

!Calc. spline coefficients of spline parametrised wrt to arclength s
subroutine clamped_cubic_spline_parametrised_wrt_arclength(N, ap, bp, cp, p, s)
    implicit none

    integer           :: i, N
    double precision           ::  s(N + 1), ap(N + 1), bp(N + 1), cp(N + 1),&
        Ma(N + 1), Mb(N + 1), Mc(N + 1), ds(N), dp(N + 1),&
        p(N + 1), dpsol(N + 1)

    ap = 0d0
    bp = 0d0
    cp = 0d0


    do 1 i = 1, N
        ds(i) = s(i + 1) - s(i)
1   continue

    do 2 i = 1, (N + 1)

        if(i == 1)then

            Mb(i) = 2d0*ds(i) !Construct linear system (LHS)
            Mc(i) = ds(i)

            dp(i) = 3d0*((p(i + 1) - p(i))/ds(i))

        elseif(i == (N + 1))then

            Ma(i) = ds(N)
            Mb(i) = 2d0*ds(N)

            dp(i) = 3d0*((p(i - 1) - p(i))/ds(i - 1))

        else

            Ma(i) = ds(i - 1)
            Mb(i) = 2d0*(ds(i - 1) + ds(i))
            Mc(i) = ds(i)

            !Assign RHS vector
            dp(i) = 3d0*((p(i + 1) - p(i))/ds(i) - (p(i) - p(i - 1))/ds(i - 1))

        endif

2   continue

    ! Solve system with Thomas Alg.
    call tridiag(N + 1, Ma, Mb, Mc, dp, dpsol)

    do 3 i = 1, (N + 1)
        bp(i) = dpsol(i) !Set b spline coefficient
3   continue

    do 4 i = 1, N

        ap(i) = (bp(i + 1) - bp(i))/(3d0*ds(i)) !Calc. remaining coefficients a, c
        cp(i) = (p(i + 1) - p(i))/ds(i) - (ds(i)/3d0)*(bp(i + 1) + 2d0*bp(i))

4   continue
    cp(N + 1) =  3d0*ap(N)*ds(N)**2 + 2d0*bp(N)*ds(N) + cp(N)

    return
end subroutine


!Calculates internal fluid variables (phi, velocities) using the boundary integral equation.
!This is only used if one wants to calc internal variables, including the pressure.
SUBROUTINE internal_quantities(no_seg, no_int, r_internal, z_internal,&
    r_surf, z_surf, z_im, presh, &
    dphi_dn, absvel, phiint, phiint_old, dh,&
    aar, bbr, ccr, ddr, eer,&
    aaz, bbz, ccz, ddz, eez,&
    aaphi, bbphi, ccphi, ddphi, eephi, pphi,&
    vel_x, vel_y, wall_swit, torus_swit, s, dt,&
    rempot, remint, aphir, bphir, cphir, dphir, ephir,&
    delPhi, a, c, vort_int, drem_dn, dtcut)
    implicit none

    integer           :: no_seg, no_int, j, k, i, wall_swit, torus_swit

    double precision  :: r_surf(no_seg + 1), z_surf(no_seg + 1), dt,&
        dphi_dn(no_seg + 1), aar(no_seg + 1), bbr(no_seg + 1),&
        ccr(no_seg + 1), ddr(no_seg + 1), eer(no_seg + 1), &
        aaz(no_seg + 1), bbz(no_seg + 1), ccz(no_seg + 1),&
        ddz(no_seg + 1), eez(no_seg + 1),&
        r_internal(no_int+1), z_internal(no_int+1), absvel(no_int+1),pi,&
        II1, II2, III, IIIa, dh, phiint(no_int+1), phiint_old(no_int+1),&
        r_around(5), z_around(5), z_im_around(5), phiint_around(5),&
        vel_x(no_int+1), vel_y(no_int+1), aaphi(no_seg + 1), bbphi(no_seg + 1),&
        ccphi(no_seg + 1), ddphi(no_seg + 1), eephi(no_seg + 1),&
        pphi(no_seg + 1), constant(5), z_im(no_seg + 1),&
        II1_im, II2_im, III_im, IIIa_im, s(no_seg + 1), presh(no_int+2),&
        rempot(no_seg + 1), remint(no_int+2), aphir(no_seg + 1), bphir(no_seg + 1),&
        cphir(no_seg + 1), dphir(no_seg + 1), ephir(no_seg + 1), delPHi,&
        f(no_int+1), f1(no_int+1), f2(no_int+1), vort_int(no_int+1), a, c,&
        drem_dn(no_seg + 1), dtcut

    z_im = 0d0   !Variable not used


    pi = 4d0*datan(1d0)
    II1_im = 0d0
    II2_im = 0d0
    III_im = 0d0
    IIIa_im = 0d0

    !Given a point (r_internal,z_internal) at which we want to find the potential and velocities, we also find
    !the potential at r_around,z_around, which are the points around r_int,z_int that make a standard finite
    !difference stencil (see fig.). Hence using a centred difference for the potential
    !and the velocity at r_int,z_int can be found.
                                                  ! Fig.           *
    do 5 i = 1, 5                                 !              dh|
        r_around(i) = 0d0                           !                | dh
        z_around(i) = 0d0                           !             *--X---*
                                                 !                |
5   continue                                     !                |

    if(torus_swit.eq.0)then
                                                      !                *
        do 1 i = 1, (no_int+1)


            r_around(1) = r_internal(i)
            r_around(2) = r_internal(i) + dh ! dh is the distance between adjacent positions
            r_around(3) = r_internal(i)
            r_around(4) = r_internal(i) - dh
            r_around(5) = r_internal(i)

            z_around(1) = z_internal(i)
            z_around(2) = z_internal(i)
            z_around(3) = z_internal(i) - dh
            z_around(4) = z_internal(i)
            z_around(5) = z_internal(i) + dh

            z_im_around(1) = -z_around(1)
            z_im_around(2) = -z_around(2)
            z_im_around(3) = -z_around(3)
            z_im_around(4) = -z_around(4)
            z_im_around(5) = -z_around(5)

            do 2 k = 1, 5

                phiint_around(k) = 0d0
                constant(k) = 0d0

                do 3 j = 1, no_seg !loop over segements on bubble surface for a particular
                                     !internal point k (eqv. p)

                    if (r_around(k).eq.0d0)then
                        ! If internal point on axis, then use alternate integration
                        call gaussaxis(r_surf(j), z_surf(j), z_around(k),&
                            aaphi(j), bbphi(j), ccphi(j), ddphi(j), eephi(j),&
                            aar(j), bbr(j), ccr(j), ddr(j), eer(j),&
                            aaz(j), bbz(j), ccz(j), ddz(j), eez(j),&
                            II1, II2, III, pphi(j), IIIa, s(j+1), s(j))

                        if(wall_swit.eq.1)then ! And image term if rigid wall is present
                            call gaussaxis(r_surf(j), z_surf(j), z_im_around(k),&
                                aaphi(j), bbphi(j), ccphi(j), ddphi(j), eephi(j),&
                                aar(j), bbr(j), ccr(j), ddr(j), eer(j),&
                                aaz(j), bbz(j), ccz(j), ddz(j), eez(j),&
                                II1_im, II2_im, III_im, pphi(j), IIIa_im, s(j+1), s(j))
                        endif

                    else ! else calculate intgrations in usual way
                        call gauss(r_surf(j), z_surf(j), r_around(k), z_around(k),&
                            aaphi(j), bbphi(j), ccphi(j), ddphi(j), eephi(j),&
                            aar(j), bbr(j), ccr(j), ddr(j), eer(j),&
                            aaz(j), bbz(j), ccz(j), ddz(j), eez(j),&
                            II1, II2, III, pphi(j), IIIa, s(j+1), s(j))

                        if(wall_swit.eq.1)then !and add image terms for the wall.
                            call gauss(r_surf(j), z_surf(j), r_around(k), z_im_around(k),&
                                aaphi(j), bbphi(j), ccphi(j), ddphi(j), eephi(j),&
                                aar(j), bbr(j), ccr(j), ddr(j), eer(j),&
                                aaz(j), bbz(j), ccz(j), ddz(j), eez(j),&
                                II1_im, II2_im, III_im, pphi(j), IIIa_im, s(j+1), s(j))
                        endif
                    endif
                    ! The boundary integral equation to calc. c(p)phi at internal point
                    phiint_around(k) = phiint_around(k) + (II1_im + II1)*dphi_dn(j) +&
                        (II2_im + II2)*dphi_dn(j + 1) - (III + III_im)
                   ! Calculating the constant c(p)
                   !     constant(k) = constant(k) - (IIIa + IIIa_im)
3               continue

                !     constant(k) = 4d0*pi - constant(k)
                phiint_around(k) = phiint_around(k)/(4d0*pi)!(c(p)=4pi for internal points)

2           continue

            phiint(i) = phiint_around(1) !Given phi at internal point and adjacent internal points
                                          !the velocity is calculated using simple finite difference scheme
            if(r_internal(i).eq.0d0)then
                vel_x(i) = 0d0
            else
                vel_x(i) = (phiint_around(2) - phiint_around(4))/(2d0*dh)
            endif

            vel_y(i) = (phiint_around(5) - phiint_around(3))/(2d0*dh)

            absvel(i) = dsqrt(vel_x(i)**2 + vel_y(i)**2)

            presh(i) = -( phiint(i) - phiint_old(i) )/dt + 1d0


1       continue

    else

        !write(*,*) 'rem etc'
        ! Calculate values of remnant potential at the grid of nodes
        do 111 i = 1, no_int + 1


            r_around(1) = r_internal(i)
            r_around(2) = r_internal(i) + dh ! dh is the distance between adjacent positions
            r_around(3) = r_internal(i)
            r_around(4) = r_internal(i) - dh
            r_around(5) = r_internal(i)

            z_around(1) = z_internal(i)
            z_around(2) = z_internal(i)
            z_around(3) = z_internal(i) - dh
            z_around(4) = z_internal(i)
            z_around(5) = z_internal(i) + dh

            z_im_around(1) = -z_around(1)
            z_im_around(2) = -z_around(2)
            z_im_around(3) = -z_around(3)
            z_im_around(4) = -z_around(4)
            z_im_around(5) = -z_around(5)

            do 22 k = 1, 5

                phiint_around(k) = 0d0
                constant(k) = 0d0

                do 33 j = 1, no_seg !loop over segements on bubble surface for a particular
                                     !internal point k (eqv. p)

                    if (r_around(k).eq.0d0)then
                        ! If internal point on axis, then use alternate integration
                        call gaussaxis(r_surf(j), z_surf(j), z_around(k),&
                            aphir(j), bphir(j), cphir(j), dphir(j), ephir(j),&
                            aar(j), bbr(j), ccr(j), ddr(j), eer(j),&
                            aaz(j), bbz(j), ccz(j), ddz(j), eez(j),&
                            II1, II2, III, rempot(j), IIIa, s(j+1), s(j))

                        if(wall_swit.eq.1)then ! And image term if rigid wall is present
                            call gaussaxis(r_surf(j), z_surf(j), z_im_around(k),&
                                aphir(j), bphir(j), cphir(j), dphir(j), ephir(j),&
                                aar(j), bbr(j), ccr(j), ddr(j), eer(j),&
                                aaz(j), bbz(j), ccz(j), ddz(j), eez(j),&
                                II1_im, II2_im, III_im, rempot(j), IIIa_im, s(j+1), s(j))

                        endif

                    else ! else calculate intgrations in usual way
                        call gauss(r_surf(j), z_surf(j), r_around(k), z_around(k),&
                            aphir(j), bphir(j), cphir(j), dphir(j), ephir(j),&
                            aar(j), bbr(j), ccr(j), ddr(j), eer(j),&
                            aaz(j), bbz(j), ccz(j), ddz(j), eez(j),&
                            II1, II2, III, rempot(j), IIIa, s(j+1), s(j))


                        if(wall_swit.eq.1)then !and add image terms for the wall.
                            call gauss(r_surf(j), z_surf(j), r_around(k), z_im_around(k),&
                                aphir(j), bphir(j), cphir(j), dphir(j), ephir(j),&
                                aar(j), bbr(j), ccr(j), ddr(j), eer(j),&
                                aaz(j), bbz(j), ccz(j), ddz(j), eez(j),&
                                II1_im, II2_im, III_im, rempot(j), IIIa_im, s(j+1), s(j))

                        endif
                    endif
                    ! The boundary integral equation to calc. c(p)phi at internal point
                    phiint_around(k) = phiint_around(k) + (II1_im + II1)*drem_dn(j) +&
                        (II2_im + II2)*drem_dn(j + 1) - (III + III_im)
                   ! Calculating the constant c(p)
                   !     constant(k) = constant(k) - (IIIa + IIIa_im)
33              continue

                !     constant(k) = 4d0*pi - constant(k)
                phiint_around(k) = phiint_around(k)/(4d0*pi)!(c(p)=4pi for internal points)

22          continue

            remint(i) = phiint_around(1) !Given phi at internal point and adjacent internal points
                                          !the velocity is calculated using simple finite difference scheme


            if(r_internal(i).eq.0d0)then
                vel_x(i) = 0d0
            else
                vel_x(i) = (phiint_around(2) - phiint_around(4))/(2d0*dh)
            endif

            vel_y(i) = (phiint_around(5) - phiint_around(3))/(2d0*dh)

            absvel(i) = dsqrt(vel_x(i)**2 + vel_y(i)**2)

            ! Now calculate vortex potential


            !f1(i) = r_internal(i)**2d0 - a**2d0 + (-c+z_internal(i))**2d0
            f1(i) = (r_internal(i)- a)**2d0 + z_internal(i)**2d0 - c**2d0

            !f2(i) = (  &
            !    (a**2d0-r_internal(i)**2d0)**2d0 + &
            !    ( (-c+z_internal(i))**2d0  )*( (-c+z_internal(i))**2d0 + 2d0*(a**2d0+r_internal(i)**2d0) )  &
            !    )**(-0.5d0)
            !f2(i) =

            !f(i) = f1(i)*f2(i)

            !vort_int(i) = ( Delphi/2d0 )*( 1d0 - ( (1d0+f(i))/2d0 )**0.5d0 )

            vort_int(i) = -Delphi*c/( sqrt(a**2d0 + c**2d0) )


            !write(*,*) vort_int(i), vort_int2(i)

            ! if(z_internal(i).gt.c)then
            ! vort_int(i) = vort_int(i) - delPhi
            !else
            ! vort_int(i) = -vort_int(i)
            !endif

            ! if(z_internal(i).lt.c)then
            !  vort_int(i) = vort_int(i) - delPhi
            ! endif

            phiint(i) = remint(i) !+ vort_int(i)


            !write(*,*) phiint_old(i), phiint(i), remint(i), vort_int(i)

            presh(i) = -( phiint(i) - phiint_old(i) )/dtcut + 1d0


111     continue


    endif

    do i = 1, (no_int + 1)
        phiint_old(i) = phiint(i)
    enddo

    return

END SUBROUTINE


!Calculates internal fluid variables (phi, velocities) using the boundary integral equation.
!This is only used if one wants to calc internal variables, including the pressure.
SUBROUTINE i2nternal_quantities(no_seg, no_int, r_internal, z_internal,&
    r_surf, z_surf, z_im, presh, &
    dphi_dn, absvel, phiint, phiint_old, dh,&
    aar, bbr, ccr, ddr, eer,&
    aaz, bbz, ccz, ddz, eez,&
    aaphi, bbphi, ccphi, ddphi, eephi, pphi,&
    vel_x, vel_y, wall_swit, torus_swit, s, dt,&
    rempot, remint, aphir, bphir, cphir, dphir, ephir,&
    delPhi, a, c, vort_int, drem_dn, dtcut)
    implicit none

    integer           :: no_seg, no_int, j, k, i, wall_swit, torus_swit

    double precision  :: r_surf(no_seg + 1), z_surf(no_seg + 1), dt,&
        dphi_dn(no_seg + 1), aar(no_seg + 1), bbr(no_seg + 1),&
        ccr(no_seg + 1), ddr(no_seg + 1), eer(no_seg + 1), &
        aaz(no_seg + 1), bbz(no_seg + 1), ccz(no_seg + 1),&
        ddz(no_seg + 1), eez(no_seg + 1),&
        r_internal(no_int+1), z_internal(no_int+1), absvel(no_int+1),pi,&
        II1, II2, III, IIIa, dh, phiint(no_int+1), phiint_old(no_int+1),&
        r_around(5), z_around(5), z_im_around(5), phiint_around(5),&
        vel_x(no_int+1), vel_y(no_int+1), aaphi(no_seg + 1), bbphi(no_seg + 1),&
        ccphi(no_seg + 1), ddphi(no_seg + 1), eephi(no_seg + 1),&
        pphi(no_seg + 1), constant(5), z_im(no_seg + 1),&
        II1_im, II2_im, III_im, IIIa_im, s(no_seg + 1), presh(no_int+2),&
        rempot(no_seg + 1), remint(no_int+2), aphir(no_seg + 1), bphir(no_seg + 1),&
        cphir(no_seg + 1), dphir(no_seg + 1), ephir(no_seg + 1), delPHi,&
        f(no_int+1), f1(no_int+1), f2(no_int+1), vort_int(no_int+1), a, c,&
        drem_dn(no_seg + 1), dtcut

    z_im = 0d0   !Variable not used


    pi = 4d0*datan(1d0)
    II1_im = 0d0
    II2_im = 0d0
    III_im = 0d0
    IIIa_im = 0d0

    !Given a point (r_internal,z_internal) at which we want to find the potential and velocities, we also find
    !the potential at r_around,z_around, which are the points around r_int,z_int that make a standard finite
    !difference stencil (see fig.). Hence using a centred difference for the potential
    !and the velocity at r_int,z_int can be found.
                                                  ! Fig.           *
    do 5 i = 1, 5                                 !              dh|
        r_around(i) = 0d0                           !                | dh
        z_around(i) = 0d0                           !             *--X---*
                                                 !                |
5   continue                                     !                |

    if(torus_swit.eq.0)then
                                                      !                *
        do 1 i = 1, (no_int+1)


            r_around(1) = r_internal(i)
            r_around(2) = r_internal(i) + dh ! dh is the distance between adjacent positions
            r_around(3) = r_internal(i)
            r_around(4) = r_internal(i) - dh
            r_around(5) = r_internal(i)

            z_around(1) = z_internal(i)
            z_around(2) = z_internal(i)
            z_around(3) = z_internal(i) - dh
            z_around(4) = z_internal(i)
            z_around(5) = z_internal(i) + dh

            z_im_around(1) = -z_around(1)
            z_im_around(2) = -z_around(2)
            z_im_around(3) = -z_around(3)
            z_im_around(4) = -z_around(4)
            z_im_around(5) = -z_around(5)

            do 2 k = 1, 5

                phiint_around(k) = 0d0
                constant(k) = 0d0

                do 3 j = 1, no_seg !loop over segements on bubble surface for a particular
                                     !internal point k (eqv. p)

                    if (r_around(k).eq.0d0)then
                        ! If internal point on axis, then use alternate integration
                        call gaussaxis(r_surf(j), z_surf(j), z_around(k),&
                            aaphi(j), bbphi(j), ccphi(j), ddphi(j), eephi(j),&
                            aar(j), bbr(j), ccr(j), ddr(j), eer(j),&
                            aaz(j), bbz(j), ccz(j), ddz(j), eez(j),&
                            II1, II2, III, pphi(j), IIIa, s(j+1), s(j))

                        if(wall_swit.eq.1)then ! And image term if rigid wall is present
                            call gaussaxis(r_surf(j), z_surf(j), z_im_around(k),&
                                aaphi(j), bbphi(j), ccphi(j), ddphi(j), eephi(j),&
                                aar(j), bbr(j), ccr(j), ddr(j), eer(j),&
                                aaz(j), bbz(j), ccz(j), ddz(j), eez(j),&
                                II1_im, II2_im, III_im, pphi(j), IIIa_im, s(j+1), s(j))
                        endif

                    else ! else calculate intgrations in usual way
                        call gauss(r_surf(j), z_surf(j), r_around(k), z_around(k),&
                            aaphi(j), bbphi(j), ccphi(j), ddphi(j), eephi(j),&
                            aar(j), bbr(j), ccr(j), ddr(j), eer(j),&
                            aaz(j), bbz(j), ccz(j), ddz(j), eez(j),&
                            II1, II2, III, pphi(j), IIIa, s(j+1), s(j))

                        if(wall_swit.eq.1)then !and add image terms for the wall.
                            call gauss(r_surf(j), z_surf(j), r_around(k), z_im_around(k),&
                                aaphi(j), bbphi(j), ccphi(j), ddphi(j), eephi(j),&
                                aar(j), bbr(j), ccr(j), ddr(j), eer(j),&
                                aaz(j), bbz(j), ccz(j), ddz(j), eez(j),&
                                II1_im, II2_im, III_im, pphi(j), IIIa_im, s(j+1), s(j))
                        endif
                    endif
                    ! The boundary integral equation to calc. c(p)phi at internal point
                    phiint_around(k) = phiint_around(k) + (II1_im + II1)*dphi_dn(j) +&
                        (II2_im + II2)*dphi_dn(j + 1) - (III + III_im)
                   ! Calculating the constant c(p)
                   !     constant(k) = constant(k) - (IIIa + IIIa_im)
3               continue

                !     constant(k) = 4d0*pi - constant(k)
                phiint_around(k) = phiint_around(k)/(4d0*pi)!(c(p)=4pi for internal points)

2           continue

            phiint(i) = phiint_around(1) !Given phi at internal point and adjacent internal points
                                          !the velocity is calculated using simple finite difference scheme
            if(r_internal(i).eq.0d0)then
                vel_x(i) = 0d0
            else
                vel_x(i) = (phiint_around(2) - phiint_around(4))/(2d0*dh)
            endif

            vel_y(i) = (phiint_around(5) - phiint_around(3))/(2d0*dh)

            absvel(i) = dsqrt(vel_x(i)**2 + vel_y(i)**2)

            presh(i) = -( phiint(i) - phiint_old(i) )/dt + 1d0


1       continue

    else

        !write(*,*) 'rem etc'
        ! Calculate values of remnant potential at the grid of nodes
        do 111 i = 1, no_int + 1


            r_around(1) = r_internal(i)
            r_around(2) = r_internal(i) + dh ! dh is the distance between adjacent positions
            r_around(3) = r_internal(i)
            r_around(4) = r_internal(i) - dh
            r_around(5) = r_internal(i)

            z_around(1) = z_internal(i)
            z_around(2) = z_internal(i)
            z_around(3) = z_internal(i) - dh
            z_around(4) = z_internal(i)
            z_around(5) = z_internal(i) + dh

            z_im_around(1) = -z_around(1)
            z_im_around(2) = -z_around(2)
            z_im_around(3) = -z_around(3)
            z_im_around(4) = -z_around(4)
            z_im_around(5) = -z_around(5)

            do 22 k = 1, 5

                phiint_around(k) = 0d0
                constant(k) = 0d0

                do 33 j = 1, no_seg !loop over segements on bubble surface for a particular
                                     !internal point k (eqv. p)

                    if (r_around(k).eq.0d0)then
                        ! If internal point on axis, then use alternate integration
                        call gaussaxis(r_surf(j), z_surf(j), z_around(k),&
                            aphir(j), bphir(j), cphir(j), dphir(j), ephir(j),&
                            aar(j), bbr(j), ccr(j), ddr(j), eer(j),&
                            aaz(j), bbz(j), ccz(j), ddz(j), eez(j),&
                            II1, II2, III, rempot(j), IIIa, s(j+1), s(j))

                        if(wall_swit.eq.1)then ! And image term if rigid wall is present
                            call gaussaxis(r_surf(j), z_surf(j), z_im_around(k),&
                                aphir(j), bphir(j), cphir(j), dphir(j), ephir(j),&
                                aar(j), bbr(j), ccr(j), ddr(j), eer(j),&
                                aaz(j), bbz(j), ccz(j), ddz(j), eez(j),&
                                II1_im, II2_im, III_im, rempot(j), IIIa_im, s(j+1), s(j))

                        endif

                    else ! else calculate intgrations in usual way
                        call gauss(r_surf(j), z_surf(j), r_around(k), z_around(k),&
                            aphir(j), bphir(j), cphir(j), dphir(j), ephir(j),&
                            aar(j), bbr(j), ccr(j), ddr(j), eer(j),&
                            aaz(j), bbz(j), ccz(j), ddz(j), eez(j),&
                            II1, II2, III, rempot(j), IIIa, s(j+1), s(j))


                        if(wall_swit.eq.1)then !and add image terms for the wall.
                            call gauss(r_surf(j), z_surf(j), r_around(k), z_im_around(k),&
                                aphir(j), bphir(j), cphir(j), dphir(j), ephir(j),&
                                aar(j), bbr(j), ccr(j), ddr(j), eer(j),&
                                aaz(j), bbz(j), ccz(j), ddz(j), eez(j),&
                                II1_im, II2_im, III_im, rempot(j), IIIa_im, s(j+1), s(j))

                        endif
                    endif
                    ! The boundary integral equation to calc. c(p)phi at internal point
                    phiint_around(k) = phiint_around(k) + (II1_im + II1)*drem_dn(j) +&
                        (II2_im + II2)*drem_dn(j + 1) - (III + III_im)
                   ! Calculating the constant c(p)
                   !     constant(k) = constant(k) - (IIIa + IIIa_im)
33              continue

                !     constant(k) = 4d0*pi - constant(k)
                phiint_around(k) = phiint_around(k)/(4d0*pi)!(c(p)=4pi for internal points)

22          continue

            remint(i) = phiint_around(1) !Given phi at internal point and adjacent internal points
                                          !the velocity is calculated using simple finite difference scheme


            if(r_internal(i).eq.0d0)then
                vel_x(i) = 0d0
            else
                vel_x(i) = (phiint_around(2) - phiint_around(4))/(2d0*dh)
            endif

            vel_y(i) = (phiint_around(5) - phiint_around(3))/(2d0*dh)

            absvel(i) = dsqrt(vel_x(i)**2 + vel_y(i)**2)

            ! Now calculate vortex potential


            !f1(i) = r_internal(i)**2d0 - a**2d0 + (-c+z_internal(i))**2d0
            f1(i) = (r_internal(i)- a)**2d0 + z_internal(i)**2d0 - c**2d0

            !f2(i) = (  &
            !    (a**2d0-r_internal(i)**2d0)**2d0 + &
            !    ( (-c+z_internal(i))**2d0  )*( (-c+z_internal(i))**2d0 + 2d0*(a**2d0+r_internal(i)**2d0) )  &
            !    )**(-0.5d0)
            !f2(i) =

            !f(i) = f1(i)*f2(i)

            !vort_int(i) = ( Delphi/2d0 )*( 1d0 - ( (1d0+f(i))/2d0 )**0.5d0 )

            vort_int(i) = -Delphi*c/( sqrt(a**2d0 + c**2d0) )


            !write(*,*) vort_int(i), vort_int2(i)

            ! if(z_internal(i).gt.c)then
            ! vort_int(i) = vort_int(i) - delPhi
            !else
            ! vort_int(i) = -vort_int(i)
            !endif

            ! if(z_internal(i).lt.c)then
            !  vort_int(i) = vort_int(i) - delPhi
            ! endif

            phiint(i) = remint(i) !+ vort_int(i)


            !write(*,*) phiint_old(i), phiint(i), remint(i), vort_int(i)

            presh(i) = -( phiint(i) - phiint_old(i) )/dtcut + 1d0


111     continue


    endif

    do i = 1, (no_int + 1)
        phiint_old(i) = phiint(i)
    enddo

    return

END SUBROUTINE


! Calculates the first derivative of a function, func, using finite diff. scheme
! n_order is the order of scheme (must be even)
! Scheme from ref. [89] (for non-uniform grids)
subroutine first_deriv(x, func, func_deriv, n_points, n_order)

    implicit none
    double precision   :: x(n_points + 1), func(n_points + 1), C, D,&
        func_deriv(n_points - n_order + 1), C_temp1, C_temp2, sum_c,&
        func_deriv_temp(n_points + 1)

    integer            :: i, j, k, m, n_points, n_order, np



    m = (n_order)/2

    np = n_points - n_order

    do 10 i = 1, (n_points + 1)

        func_deriv_temp(i) = 0d0

10  continue

    do 4 i = 1, (np + 1)
        func_deriv(i) = 0d0
4   continue


    do 3 i = (m + 1), (n_points - m + 1)

        C = 0d0
        D = 0d0
        sum_c = 0d0

        do 2 j = (i - m), (i + m)

            C_temp2 = 1d0

            do 1 k = (i - m), (i + m)

                if((k.eq.j).or.(i.eq.k))then

                    C_temp1 = 1d0

                else

                    C_temp1 = (x(k) - x(i))/(x(k) - x(j))

                endif

                C = C_temp1*C_temp2

                C_temp2 = C

1           continue

            if(i.ne.j)then
                Sum_C = sum_C + C
            endif

            if(i.ne.j)then

                D = (func(j) - func(i))/(x(j) - x(i))

            else

                D = 0d0

            endif

            func_deriv_temp(i) = C*D + func_deriv_temp(i)

2       continue
3   continue

    do 11 i = 1, (np + 1)

        func_deriv(i) = func_deriv_temp(m + i)

11  continue

    return
end subroutine

! Calculates the second derivative of a function, func, using finite diff. scheme
! n_order is the order of scheme (must be even)
! Scheme from ref. [89] (for non-uniform grids)
subroutine second_deriv(x, func, func_deriv, n_points, n_order)

    implicit none
    double precision   :: x(n_points + 1), func(n_points + 1), C, D,&
        func_deriv_temp(n_points + 1), C_temp1, C_temp2, sum_c,&
        Delta, a, mult, func_deriv(n_points - n_order + 1)

    integer            :: i, j, k, m, n_points, n_order, np



    m = (n_order)/2

    np = n_points - n_order

    do 10 i = 1, (n_points + 1)
        func_deriv_temp(i) = 0d0
10  continue

    do 4 i = 1, (np + 1)
        func_deriv(i) = 0d0
4   continue

    do 3 i = (m + 1), (n_points - m + 1)

        C = 0d0
        D = 0d0
        sum_c = 0d0

        mult = 1d0


        do 2 j = (i - m), (i + m)

            C_temp2 = 1d0
            mult = 1d0

            do 1 k = (i - m), (i + m)

                if((i.eq.k).or.(j.eq.k))then
                    Delta = 1d0
                else
                    Delta = x(k) - x(i)
                endif

                mult = Delta*mult

1           continue

            a = 0d0

            do 8 k = (i - m), (i + m)

                if((i.eq.k).or.(j.eq.k))then

                    C_temp1 = 1d0
                else

                    a = a + mult/(x(k) - x(i))
                    C_temp1 = 1d0/(x(k) - x(j))

                endif

                C = C_temp1*C_temp2
                C_temp2 = C

8           continue

            C = -2d0*a*C

            if(i.ne.j)then
                Sum_C = sum_C + C
            endif

            if(i.ne.j)then
                D = (func(j) - func(i))/(x(j) - x(i))
            else
                D = 0d0
            endif

            func_deriv_temp(i) = C*D + func_deriv_temp(i)

2       continue
3   continue

    do 11 i = 1, (np + 1)

        func_deriv(i) = func_deriv_temp(m + i)

11  continue

    return
end subroutine

! Calculates solution of linear system using Gaussian elimination
! Taken from Numerical Recipes book
SUBROUTINE GaussJ(A, n, B)
    implicit none

    ! A is an input matirx of NxN elements stored in an array of physical dimensions NPxNP
    ! B is an input matirix of NxM elements containing M right hand side vectors, stored in an
    ! array of physical dimension NPXMP
    ! On output, A is replaced by its inverse and B the corresponding set of solution vectors
    ! since i know the size of matrix, can set np = n etc...


    integer, parameter :: m = 1 !should be as large as the largest anticpated value of n

    integer  :: n, ipiv(n), indxr(n), indxc(n), ll, i, j, k, l,&
        irow, icol

    double precision :: A(n, n), B(n,m), big, pivinv, dum


    do 11 j = 1, n
        ipiv(j) = 0
11  continue

    do 22 i = 1, n
        big = 0d0
        do 13 j = 1, n
            if(ipiv(j).ne.1)then
                do 12 k = 1, n
                    if(ipiv(k).eq.0)then
                        if(abs(A(j, k)).ge.big)then
                            big = abs(A(j, k))
                            irow = j
                            icol = k
                        endif
                    elseif(ipiv(k).gt.1)then
                        write(*,*) 'singular matrix'
                        stop
                    endif
12              continue
            endif
13      continue

        ipiv(icol) = ipiv(icol) + 1

        if(irow.ne.icol)then
            do 14 l = 1, n

                dum = A(irow, l)
                A(irow, l) = A(icol, l)
                A(icol, l) = dum

14          continue

            do 15 l = 1, m

                dum = B(irow, l)
                B(irow, l) = B(icol, l)
                B(icol, l) = dum

15          continue

        endif

        indxr(i) = irow
        indxc(i) = icol

        if(A(icol, icol).eq.0d0)then
            write(*,*) 'singular matrix'
        endif

        pivinv = 1d0/A(icol, icol)

        A(icol, icol) = 1d0

        do 16 l = 1, n

            A(icol, l) = A(icol, l)*pivinv

16      continue

        do 17 l = 1, m

            B(icol, l) = B(icol, l)*pivinv

17      continue

        do 21 ll = 1, n

            if(ll.ne.icol)then

                dum = A(ll, icol)
                A(ll, icol) = 0d0

                do 18 l = 1, n

                    A(ll, l) = A(ll, l) - A(icol, l)*dum

18              continue

                do 19 l = 1, m

                    B(ll, l) = B(ll, l) - B(icol, l)*dum

19              continue

            endif

21      continue
22  continue

    do 24 l = n, 1, -1
        if(indxr(l).ne.indxc(l))then
            do 23 k = 1, n
                dum = A(k, indxr(l))
                A(k, indxr(l)) =  A(k, indxc(l))
                A(k, indxc(l)) = dum
23          continue
        endif
24  continue
    return
END SUBROUTINE

subroutine reflect_surface(r_graph, z_graph, r, z, np)

    !Reflects surface co-ordinates in the z-axis (soley for
    !post-processing/plotting purposes)


    implicit none

    integer           :: i, j, l, np
    double precision  :: r_graph(2*np + 1), z_graph(2*np + 1), r(np + 1), z(np + 1)


    do 1 l = 1, (np + 1)

        r_graph(l) = r(l)
        z_graph(l) = z(l)

1   continue

    j = 1

    do 2 i = (np + 2), 2*np
        r_graph(i) = -r(i - 2*j)
        z_graph(i) =  z(i - 2*j)
        j = j + 1
2   continue

    r_graph(2*np + 1) = r(1)
    z_graph(2*np + 1) = z(1)

    return
end subroutine

SUBROUTINE reflect_surface_torus(r_graph, z_graph, r_graphop, z_graphop, r, z, np)
    !Reflects surface co-ordinates in the z-axis (soley for
    !post-processing/plotting purposes)

    implicit none

    integer           :: l, np
    double precision  :: r_graph(np+1), z_graph(np+1), r_graphop(np+1),&
        z_graphop(np+1), r(np + 1),&
        z(np + 1)


    do 1 l = 1, (np + 1)

        r_graph(l) = r(l)
        z_graph(l) = z(l)
        r_graphop(l) = -r(l)
        z_graphop(l) = z(l)

1   continue


    return
END SUBROUTINE



SUBROUTINE iterative_arclength_calc(r, z, ars, brs, crs, drs, ers, azs, bzs, czs,&
    dzs, ezs, s, length, np, torus_switch)

    implicit none

    integer          :: i, np, torus_switch
    double precision :: r(np + 1), z(np + 1), ar(np + 1), br(np + 1), cr(np + 1),&
        dr(np + 1), er(np + 1),&
        az(np + 1), bz(np + 1), cz(np + 1), dz(np + 1), ez(np + 1),&
        s(np + 1), ars(np + 1), brs(np + 1), crs(np + 1),&
        drs(np + 1), ers(np + 1),&
        azs(np + 1), bzs(np + 1), czs(np + 1), dzs(np + 1), ezs(np + 1),&
        ss, s_new(np + 1), epsilon, length, real_np


    s_new = 0d0
    s = 0d0
    ar = 0d0
    br = 0d0
    cr = 0d0
    dr = 0d0
    er = 0d0
    az = 0d0
    bz = 0d0
    cz = 0d0
    dz = 0d0
    ez = 0d0

    !First calc. splines for r, z with parametrisation [0,1] on each segment.
    if (torus_switch.eq.0) then                 !before collapse
        call Quintic_Natural(np, r, ar, br, cr, dr, er)
        call Quintic_Clamped(np, z, az, bz, cz, dz, ez)
    else                                        !for toroidal bubble (bubble surface)
        call Quintic_periodic(np, r, ar, br, cr, dr, er)
        call Quintic_periodic(np, z, az, bz, cz, dz, ez)
    endif



    do  i = 1, np
        !use these splines to calculate length of segments (ss).
        call segment_integrate(ar(i), br(i), cr(i), dr(i), er(i), az(i),&
            bz(i), cz(i), dz(i), ez(i), ss)
        s(i + 1) = s(i) + ss
    enddo




    do

          !use calculated arclength to determine new spline coefficients (which are
          !now parametrised wrt arclength)
        if (torus_switch.eq.0) then
            call Quintic_Natural_parameterised_arclength(np, ars, brs, crs, drs, ers, r, s)
            call Quintic_Clamped_parameterised_arclength(np, azs, bzs, czs, dzs, ezs, z, s)
        else
            call Quintic_periodic_parameterised_arclength(np, ars, brs, crs, drs, ers, r, s)
            call Quintic_periodic_parameterised_arclength(np, azs, bzs, czs, dzs, ezs, z, s)
        endif


        do i = 1, np
            !use these new splines to calc a new (and better) approximation to length of segements
            !and so total arclength
            call segment_integrate_arc(ars(i), brs(i), crs(i), drs(i), ers(i), azs(i),&
                bzs(i), czs(i), dzs(i), ezs(i), s(i + 1), s(i), ss)
            s_new(i + 1) = s_new(i) + ss
        enddo


         !If the difference between old and new arclength approximations is sufficently small,
         !then we can leave this loop, otherwise go back to the start.
        epsilon = dabs(s_new(np + 1) - s(np + 1))/s(np + 1)

        do i = 1, (np + 1)
            s(i) = s_new(i)
            s_new(i) = 0d0
        enddo


        if(epsilon.lt.1d-15)exit

    enddo


    real_np = real(np)

    length = s(np + 1)/real_np

    return
END SUBROUTINE

!This rountine redistributes a variable f (using the splines) so it equally spaced wrt arclength.
subroutine redistribute(f, afs, bfs, cfs, s, length, np)
    implicit none

    integer :: np, i, j
    double precision :: f(np + 1), s(np + 1), afs(np + 1), bfs(np + 1), cfs(np + 1),&
        f_new_arc(np + 1), ii, length


    do 5 i = 1, (np - 1)
        ii = real(i)
        do 6 j = 1, np
            !Use splines to determine new values at arclength points s(i)=i*length, with np*length=total arclength
            if ((s(j + 1).ge.(ii*length)).and.(s(j).lt.(ii*length)))then

                f_new_arc(i + 1) = afs(j)*(ii*length - s(j))**3 + bfs(j)*(ii*length - s(j))**2 + cfs(j)*(ii*length - s(j)) + f(j)

            endif
6       continue

5   continue

    f_new_arc(1) = f(1) !End-points remain constant
    f_new_arc(np + 1) = f(np + 1)

    do 7 i = 1, (np + 1)

        f(i) = f_new_arc(i) !Replace old points with new

7   continue

    return
end subroutine

SUBROUTINE redistribute_new(f, afs, bfs, cfs, dfs, efs, s, length, np, torus_switch)
    implicit none

    integer :: np, i, j, torus_switch
    double precision :: f(np + 1), s(np + 1), afs(np + 1), bfs(np + 1), cfs(np + 1),&
        dfs(np + 1), efs(np + 1), f_new_arc(np + 1), ii, length

    if(torus_switch.eq.0)then
        do 5 i = 1, (np - 1)
            ii = real(i)
            do 6 j = 1, np

                if ((s(j + 1).ge.(ii*length)).and.(s(j).lt.(ii*length)))then

                    f_new_arc(i + 1) = afs(j)*(ii*length - s(j))**5 + bfs(j)*(ii*length - s(j))**4 &
                        + cfs(j)*(ii*length - s(j))**3 +  dfs(j)*(ii*length - s(j))**2 &
                        + efs(j)*(ii*length - s(j)) + f(j)

                endif
6           continue
5       continue



    else
        do 50 i = 1, (np - 1)
            ii = dble(i)
            do 60 j = 1, np

                if ((s(j + 1).ge.(ii*length)).and.(s(j).lt.(ii*length)))then

                    f_new_arc(i + 1) = afs(j)*(ii*length - s(j))**5 + bfs(j)*(ii*length - s(j))**4 &
                        + cfs(j)*(ii*length - s(j))**3 +  dfs(j)*(ii*length - s(j))**2 &
                        + efs(j)*(ii*length - s(j)) + f(j)
                endif
60          continue
50      continue

    endif

        f_new_arc(1) = f(1) !End-points remain constant
        f_new_arc(np + 1) = f(np + 1)

    do 13 i = 1, (np + 1)

        f(i) = f_new_arc(i) !Replace old points with new

13  continue

    return
END SUBROUTINE


!This routine smooths an odd function f, using the standard smoothing formula
!(see ref. [97])
subroutine smooth_odd(f, np)

    implicit none

    integer :: np, i
    double precision :: f(np + 1), f_smooth(np + 1)

    do 1 i = 1, (np + 1)

        if(i.eq.1)then

            f_smooth(i) = 0d0

        elseif(i.eq.2)then

            f_smooth(i) = (1d0/16d0)*(f(i) + 4d0*f(i - 1) + 10d0*f(i) + 4d0*f(i + 1) - f(i + 2))

        elseif(i.eq.(np + 1))then

            f_smooth(i) = 0d0

        elseif(i.eq.np)then

            f_smooth(i) = (1d0/16d0)*(-f(i - 2) + 4d0*f(i - 1) + 10d0*f(i) + 4d0*f(i + 1) + f(i))

        else

            f_smooth(i) = (1d0/16d0)*(-f(i - 2) + 4d0*f(i - 1) + 10d0*f(i) + 4d0*f(i + 1) - f(i + 2))

        endif

1   continue

    do 2 i = 1, (np + 1)

        f(i) = f_smooth(i)

2   continue

    return
end subroutine

!This routine smooths an even function f, using the standard smoothing formula
!(see ref. [97])
subroutine smooth_even(f, np)

    implicit none

    integer :: np, i
    double precision :: f(np + 1), f_smooth(np + 1)

    do 1 i = 1, (np + 1)

        if(i.eq.1)then

            f_smooth(i) = (1d0/16d0)*(-f(i + 2) + 4d0*f(i + 1) + 10d0*f(i) + 4d0*f(i + 1) - f(i + 2))

        elseif(i.eq.2)then

            f_smooth(i) = (1d0/16d0)*(-f(i) + 4d0*f(i - 1) + 10d0*f(i) + 4d0*f(i + 1) - f(i + 2))

        elseif(i.eq.(np + 1))then

            f_smooth(i) = (1d0/16d0)*(-f(i - 2) + 4d0*f(i - 1) + 10d0*f(i) + 4d0*f(i - 1) - f(i - 2))

        elseif(i.eq.np)then

            f_smooth(i) = (1d0/16d0)*(-f(i - 2) + 4d0*f(i - 1) + 10d0*f(i) + 4d0*f(i + 1) - f(i))
        else

            f_smooth(i) = (1d0/16d0)*(-f(i - 2) + 4d0*f(i - 1) + 10d0*f(i) + 4d0*f(i + 1) - f(i + 2))

        endif

1   continue

    do 2 i = 1, (np + 1)

        f(i) = f_smooth(i)

2   continue
    return
end subroutine


SUBROUTINE vr_smooth_torus_r_z(f, n, alpha)

    implicit none

    integer           :: n, i
    double precision  :: f(n + 1), f_smooth(n + 1), alpha

    f_smooth = 0d0

    DO i = 3, (n-1)
        f_smooth(i) = f(i) - alpha*( f(i-2) - 4d0*f(i-1) + 6d0*f(i) - 4d0*f(i+1) + f(i+2) )
    ENDDO

    f_smooth(1) = f(1) - alpha*( f(n-1) - 4d0*f(n) + 6d0*f(1) - 4d0*f(2) + f(3) )
    f_smooth(2) = f(2) - alpha*( f(n) - 4d0*f(1) + 6d0*f(2) - 4d0*f(3) + f(4) )
    f_smooth(n) = f(n) - alpha*( f(n-2) - 4d0*f(n-1) + 6d0*f(n) - 4d0*f(1) + f(2) )
    !f_smooth(np+1) = f(np+1) - alpha*( f(np-1) - 4d0*f(np) + 6d0*f(1) - 4d0*f(2) + f(3) )
    !f_smooth(1) = f(1)
    f_smooth(n+1) = f_smooth(1)


    f = 0d0
    DO i=1,(n+1)
        f(i) = f_smooth(i)
    ENDDO


    RETURN
END SUBROUTINE


SUBROUTINE vr_smooth_torus_phi(f, np, alpha, delphi)

    implicit none

    integer           :: np, i
    double precision  :: f(np + 1), f_smooth(np + 1), alpha, delphi

    f_smooth = 0d0



    DO i = 3, (np-1)
        f_smooth(i) = f(i) - alpha*( f(i-2) - 4d0*f(i-1) + 6d0*f(i) - 4d0*f(i+1) + f(i+2) )
    ENDDO

    f_smooth(1) = f(1) - alpha*( (f(np-1)-delphi) - 4d0*(f(np)-delphi) + 6d0*f(1) -&
        4d0*f(2) + f(3) )
    f_smooth(2) = f(2) - alpha*( (f(np)-delphi) - 4d0*f(1) + 6d0*f(2) - 4d0*f(3) + f(4) )
    f_smooth(np) = f(np) - alpha*( f(np-2) - 4d0*f(np-1) + 6d0*f(np) - 4d0*f(np+1) + (f(2)+delphi) )
    f_smooth(np+1) = f(np+1) - alpha*( f(np-1) - 4d0*f(np) + 6d0*f(np+1) - 4d0*(f(2)+delphi) + (f(3)+delphi) )
    !f_smooth(np+1) = f(np+1) - alpha*( f(np-1) - 4d0*f(np) + 6d0*f(np+1) -&
     !                           4d0*(f(2)+delphi) + (f(3)+delphi) )

    !f_smooth(1) = f(1)
    !f_smooth(2) = f(2) - (1d0/4d0)*( -f(1) + 2d0*f(2) - f(3) )
    !f_smooth(np) = f(np) - (1d0/4d0)*( -f(np-1) + 2d0*f(np) - f(np+1) )
    !f_smooth(np+1) = f(np+1)

    f = 0d0
    DO i=1,(np+1)
        f(i) = f_smooth(i)
    ENDDO

    RETURN
END SUBROUTINE


subroutine calc_vol(np, rv, arv, brv, crv, drv, erv, azv, bzv, czv, dzv, ezv, sv, vvol)

    implicit none

    double precision :: rv(np + 1), arv(np + 1), brv(np + 1), crv(np + 1), drv(np + 1),&
        erv(np + 1), sv(np + 1), vvol, d_vol, azv(np + 1), bzv(np + 1),&
        czv(np + 1), dzv(np + 1), ezv(np + 1)

    integer          :: np, j

    vvol = 0d0

    do 1 j = 1, np

        call calc_vol_seg(arv(j), brv(j), crv(j), drv(j), erv(j), rv(j), &
            azv(j), bzv(j), czv(j), dzv(j), ezv(j),&
            sv(j + 1), sv(j), d_vol)


        vvol = vvol + d_vol

1   continue

    return
end subroutine

subroutine calc_vol_seg(aar, bbr, ccr, ddr, eer, rj, aaz, bbz, ccz, ddz, eez, s2, s1, I_seg)
    implicit none
    double precision  :: aar, bbr, ccr, ddr, eer, gi(10), w(10), rj,&
        I_seg, s2, s1, ds, z_prime,&
        rr, pi, ss, aaz, bbz, ccz, ddz, eez

    integer           :: l



    I_seg = 0d0

    gi(1) = 0.97390652851717172008d0
    gi(2) = 0.86506336668898451073d0
    gi(3) = 0.67940956829902440623d0
    gi(4) = 0.43339539412924719080d0
    gi(5) = 0.14887433898163121089d0
    gi(6) = -gi(5)                      !ordinary 10 point gauss points/wieghts
    gi(7) = -gi(4)
    gi(8) = -gi(3)
    gi(9) = -gi(2)
    gi(10) = -gi(1)

    w(1) = 0.06667134430868813759d0
    w(2) = 0.14945134915058059315d0
    w(3) = 0.21908636251598204400d0
    w(4) = 0.26926671930999635509d0
    w(5) = 0.29552422471475287017d0
    w(6) = w(5)
    w(7) = w(4)
    w(8) = w(3)
    w(9) = w(2)
    w(10) = w(1)

    pi = 4d0*datan(1d0)

    ds = s2 - s1

    do 1 l = 1, 10

        ss = 0.5d0*(ds*gi(l) + s2 + s1)

        rr = aar*(ss - s1)**5 + bbr*(ss - s1)**4 + ccr*(ss - s1)**3 +&
            ddr*(ss - s1)**2 + eer*(ss - s1) + rj

        z_prime = 5d0*aaz*(ss - s1)**4 + 4d0*bbz*(ss - s1)**3 + 3d0*ccz*(ss - s1)**2 +&
            2d0*ddz*(ss - s1) + eez

        !!z_prime = dabs(z_prime)

        I_seg = I_seg + pi*(rr**2)*z_prime*w(l)

1   continue

    I_seg = ds*0.5d0*I_seg

    return
end subroutine


SUBROUTINE Quintic_Natural(nn, p, aas, bbs, ccs, dds, ees)
    IMPLICIT NONE
        !Natural quintic spline with parameterisation [0,1] over each segment

    INTEGER                                :: i,nn, INFO
    INTEGER, DIMENSION(nn-1)               :: IPIV


    DOUBLE PRECISION, DIMENSION(nn-1,nn-1) :: a, b, c, d, e, temp_d
    DOUBLE PRECISION, DIMENSION(nn-1)      :: m, v, ff, aa, temp_f, temp_v, y, dd
    DOUBLE PRECISION, DIMENSION(nn)        :: aas, bbs, ccs, dds, ees
    DOUBLE PRECISION, DIMENSION(nn+1)      :: mm, vv, p
    DOUBLE PRECISION, DIMENSION(nn-2)      :: al, au


    !Initialise variables.
    a = 0d0
    b = 0d0
    c = 0d0
    d = 0d0
    e = 0d0
    m = 0d0
    v = 0d0
    ff = 0d0
    aa = 0d0
    al = 0d0
    au = 0d0
    mm = 0d0
    vv = 0d0
    dd = 0d0
    temp_d = 0d0
    temp_f = 0d0
    temp_v = 0d0
    y = 0d0
    aas = 0d0
    bbs = 0d0
    ccs = 0d0
    dds = 0d0
    ees = 0d0

    DO 1 i=1, (nn-1) !Entries of A in Ab=Bd, let E=(A^-1)*B and solve AE=B and Cb+Dd=F
        aa(i)  = 8d0
        b(i,i) = -2d0
        c(i,i) = -16d0/15d0
        d(i,i) = 4d0/3d0
        ff(i)  = (p(i+2)-p(i+1))-(p(i+1)-p(i))!Here, x(i) is the function we are approximating (bubble surface etc)
    !                                  at the ith node

1   CONTINUE


    DO 2 i=1,(nn-2)
        au(i)    = 2d0
        al(i)    = 2d0
        b(i,i+1) = 1d0
        b(i+1,i) = 1d0
        c(i,i+1) = -7d0/15d0
        c(i+1,i) = -7d0/15d0
        d(i,i+1) = 1d0/3d0
        d(i+1,i) = 1d0/3d0
2   CONTINUE

    !Now solve system using tridiagonal solver from Lapack.
    CALL DGTSV(nn-1,nn-1,al,aa,au,b,nn-1,INFO)

    e = b

    !Lapack gives E, then M=EV and (CE+D)d=F. So now find d=(CE+D)^(-1)*F

    !Use BLAS for matrix manipulations, i.e. to get CE+D
    CALL DGEMM('N','N',nn-1,nn-1,nn-1,1d0,c,nn-1,e,nn-1,1d0,d,nn-1)

    !Now we have d= CE+D
    !Now solve dds=(CE+D)^(-1)*F.

    CALL DGESV(nn-1,1,d,nn-1,IPIV,ff,nn-1,INFO)!This solves (CE+D)v=dv=f.

    dd=ff ! This is our vector of second derivatives.

    CALL DGEMV('N',nn-1,nn-1,1d0,e,nn-1,dd,1,0d0,y,1)!This solves m=ev.

    DO 3 i=2, nn
        dds(i) = dd(i-1)!These are the 4th derivatives of the spline function at the nodes.
        bbs(i) = y(i-1)!These are the 2nd derivatives of the spline function at the nodes.
3   CONTINUE

    dds(1)=0d0
    bbs(1)=0d0
    dds(nn+1)=0d0
    bbs(nn+1)=0d0

    !For the natural spline the second and fourth derivatives vanish at the end points.
    !We now calculate the coefficients of the spline function in terms of mm and vv.

    DO i=1,(nn)
        aas(i) = (1d0/5d0)*(bbs(i+1)-bbs(i))
        ccs(i) = (1d0/3d0)*(dds(i+1)-dds(i))-(2d0/3d0)*(bbs(i+1)+2d0*bbs(i))
        ees(i) = (p(i+1)-p(i))-(1d0/3d0)*(dds(i+1)+2d0*dds(i))+&
            (1d0/15d0)*(7d0*bbs(i+1)+8d0*bbs(i))

    ENDDO


    RETURN
END SUBROUTINE

!**************************************************************************************************
!**************************************************************************************************
!**************************************************************************************************

SUBROUTINE Quintic_Natural_parameterised_arclength(nn, aps, bps, cps, dps, eps, p, s)
    IMPLICIT NONE
        !Natural quintic spline parameterised by arclength.

    INTEGER                                 :: i,nn, INFO, INFO2
    INTEGER, DIMENSION(nn-1)                :: IPIV

    DOUBLE PRECISION, DIMENSION(nn-1,nn-1)  :: a, b, c, d, e, temp_d
    DOUBLE PRECISION, DIMENSION(nn-1)       :: m, v, ff, aa, y, temp_f, temp_v
    DOUBLE PRECISION, DIMENSION(nn)         :: ds, aps, bps,&
        cps, dps, eps
    DOUBLE PRECISION, DIMENSION(nn+1)       :: mm, vv, p, s
    DOUBLE PRECISION, DIMENSION(nn-2)       :: al, au


    !Initialise variables.
    a = 0d0
    b = 0d0
    c = 0d0
    d = 0d0
    e = 0d0
    m = 0d0
    v = 0d0
    ff = 0d0
    aa = 0d0
    al = 0d0
    au = 0d0
    mm = 0d0
    vv = 0d0
    ds = 0d0
    temp_d = 0d0
    temp_f = 0d0
    temp_v = 0d0
    y = 0d0
    aps = 0d0
    bps = 0d0
    cps = 0d0
    dps = 0d0
    eps = 0d0

    DO i=1, nn
        ds(i) = s(i+1)-s(i) !Length of segment i
    ENDDO

    DO 1 i=1, (nn-1) !Entries of A,B in AM=BV, let E=(A^-1)*B and solve AE=B and CM+DV=F
        aa(i)  = (4d0)*(ds(i)+ds(i+1))
        b(i,i) = (-1d0)*(ds(i)**(-1d0)+ds(i+1)**(-1d0))
        c(i,i) = (-8d0/15d0)*((ds(i))**(3d0)+(ds(i+1))**(3d0))
        d(i,i) = (2d0/3d0)*(ds(i)+ds(i+1))
        ff(i)  = (1d0/ds(i+1))*(p(i+2)-p(i+1))-(1d0/ds(i))*(p(i+1)-p(i))!Here, x(i) is the function we are approximating (bubble surface etc)
                                     !at the ith node.
1   CONTINUE

    DO 2 i=1,(nn-2)
        au(i)    = 2d0*ds(i+1)
        al(i)    = 2d0*ds(i+1)
        b(i,i+1) = ds(i+1)**(-1d0)
        b(i+1,i) = ds(i+1)**(-1d0)
        c(i,i+1) = (-7d0/15d0)*(ds(i+1)**(3d0))
        c(i+1,i) = (-7d0/15d0)*(ds(i+1)**(3d0))
        d(i,i+1) = (1d0/3d0)*ds(i+1)
        d(i+1,i) = (1d0/3d0)*ds(i+1)
2   CONTINUE

    !Now solve system using tridiagonal solver from Lapack.
    CALL DGTSV(nn-1,nn-1,al,aa,au,b,nn-1,INFO)

    e = b


    !Lapack gives E, then M=EV and (CE+D)V=F. So now find V=(CE+D)^(-1)*F
    !Use BLAS for matrix manipulations, i.e. to get CE+D

    CALL DGEMM('N','N',nn-1,nn-1,nn-1,1d0,c,nn-1,e,nn-1,1d0,d,nn-1)

    !Now we have d= CE+D
    !Now solve V=(CE+D)^(-1)*F.

    temp_f = ff
    temp_d = d

    CALL DGESV(nn-1,1,temp_d,nn-1,IPIV,temp_f,nn-1,INFO2)!This solves (CE+D)v=dv=f.

    v=temp_f

    CALL DGEMV('N',nn-1,nn-1,1d0,e,nn-1,v,1,0d0,y,1)!This solves m=ev.

    DO 3 i=2, nn
        dps(i) = v(i-1)!These are the 4th derivatives of the spline function at the nodes.
        bps(i) = y(i-1)!These are the 2nd derivatives of the spline function at the nodes.
3   CONTINUE

    dps(1)=0d0
    bps(1)=0d0
    dps(nn+1)=0d0
    bps(nn+1)=0d0

    !We now calculate the coefficients of the spline function in terms of mm and vv.


    DO i=1,(nn)
        aps(i) = (1d0/(5d0*ds(i)))*(bps(i+1)-bps(i))
        cps(i) = (1d0/(3d0*ds(i)))*(dps(i+1)-dps(i))-((2d0*ds(i))/3d0)*(bps(i+1)+2d0*bps(i))
        eps(i) = (1d0/ds(i))*(p(i+1)-p(i))-(ds(i)/3d0)*(dps(i+1)+2d0*dps(i))+&
            ((ds(i)**(3d0))/15d0)*(7d0*bps(i+1)+8d0*bps(i))
    ENDDO


    RETURN
END SUBROUTINE

!***********************************************************************************************
!***********************************************************************************************
!***********************************************************************************************

SUBROUTINE Quintic_Clamped(nn, p, aas, bbs, ccs, dds, ees)
    IMPLICIT NONE
        !Clamped quintic spline with parameterisation [0,1] over each segment

    INTEGER                                  :: i,nn, INFO, INFO2
    INTEGER, DIMENSION(nn+1)                 :: IPIVc


    DOUBLE PRECISION, DIMENSION(nn+1,nn+1)   :: ac, bc, cc, dc, ec, temp_dc
    DOUBLE PRECISION, DIMENSION(nn)          :: alc, auc
    DOUBLE PRECISION, DIMENSION(nn+1)        :: mc, vc, ffc, aac, temp_fc, temp_vc, yc, p,&
        aas, bbs, ccs, dds, ees



    !Initialise variables.
    ac = 0d0
    bc = 0d0
    cc = 0d0
    dc = 0d0
    ec = 0d0
    mc = 0d0
    vc = 0d0
    ffc = 0d0
    aac = 0d0
    alc = 0d0
    auc = 0d0
    temp_dc = 0d0
    temp_fc = 0d0
    temp_vc = 0d0
    yc = 0d0
    aas = 0d0
    bbs = 0d0
    ccs = 0d0
    dds = 0d0
    ees = 0d0


    !Now define the entries in the matrices: AM = BV and CM+DV = F
    DO i=2, nn
        aac(i)  = (8d0)
        bc(i,i) = (-2d0)
        cc(i,i) = (-16d0/15d0)
        dc(i,i) = (4d0/3d0)
        ffc(i)  = (p(i+1)-p(i))-(p(i)-p(i-1))
    ENDDO

    DO i=1, nn
        auc(i)    = 2d0
        alc(i)    = 2d0
        bc(i,i+1) = (1d0)
        bc(i+1,i) = (1d0)
        cc(i,i+1) = (-7d0/15d0)
        cc(i+1,i) = (-7d0/15d0)
        dc(i,i+1) = (1d0/3d0)
        dc(i+1,i) = (1d0/3d0)

    ENDDO

    aac(1)        = (4d0)
    aac(nn+1)     = (4d0)
    bc(1,1)       = (-1d0)
    bc(nn+1,nn+1) = (-1d0)
    cc(1,1)       = (-8d0/15d0)
    cc(nn+1,nn+1) = (-8d0/15d0)
    dc(1,1)       = (2d0/3d0)
    dc(nn+1,nn+1) = (2d0/3d0)
    ffc(1)        = (-1d0)*(p(1)-p(2))
    ffc(nn+1)     = (1d0)*(p(nn)-p(nn+1))

    !Now solve system using tridiagonal solver from Lapack.
    CALL DGTSV(nn+1,nn+1,alc,aac,auc,bc,nn+1,INFO)

    ec = bc

    !Lapack gives E, then M=EV and (CE+D)V=F. So now find V=(CE+D)^(-1)*F
    !Use BLAS for matrix manipulations, i.e. to get CE+D

    CALL DGEMM('N','N',nn+1,nn+1,nn+1,1d0,cc,nn+1,ec,nn+1,1d0,dc,nn+1)

    !Now we have d= CE+D
    !Now solve V=(CE+D)^(-1)*F.

    temp_fc = ffc
    temp_dc = dc

    CALL DGESV(nn+1,1,temp_dc,nn+1,IPIVc,temp_fc,nn+1,INFO2)!This solves (CE+D)v=dv=f.

    dds=temp_fc

    CALL DGEMV('N',nn+1,nn+1,1d0,ec,nn+1,dds,1,0d0,yc,1)!This solves m=ev.

    bbs = yc


    DO i=1,(nn)
        aas(i) = (1d0/5d0)*(bbs(i+1)-bbs(i))
        ccs(i) = (1d0/3d0)*(dds(i+1)-dds(i))-(2d0/3d0)*(bbs(i+1)+2d0*bbs(i))
        ees(i) = (p(i+1)-p(i))-(1d0/3d0)*(dds(i+1)+2d0*dds(i))+&
            (1d0/15d0)*(7d0*bbs(i+1)+8d0*bbs(i))
    ENDDO

    ccs(nn+1) = 10d0*aas(nn)+4d0*bbs(nn)+ccs(nn)
    ees(nn+1) = 5d0*aas(nn)+4d0*bbs(nn)+3d0*ccs(nn)+2d0*dds(nn)+ees(nn)


    RETURN
END SUBROUTINE

!*************************************************************************************************
!*************************************************************************************************
!*************************************************************************************************

SUBROUTINE Quintic_Clamped_parameterised_arclength(nn, aps, bps, cps, dps, eps, p, s)
    IMPLICIT NONE
        !Clamped quintic spline parameterised by arclength.

    INTEGER                                  :: i,nn,INFO,INFO2
    INTEGER, DIMENSION(nn+1)                 :: IPIVc


    DOUBLE PRECISION, DIMENSION(nn+1,nn+1)   :: ac, bc, cc, dc, ec, temp_dc
    DOUBLE PRECISION, DIMENSION(nn)          :: alc, auc
    DOUBLE PRECISION, DIMENSION(nn+1)        :: mc, vc, ffc, aac, temp_fc, temp_vc, yc, p, s,&
        aps, bps, cps, dps, eps
    DOUBLE PRECISION, DIMENSION(nn)          :: ds



    !Initialise variables.
    ac = 0d0
    bc = 0d0
    cc = 0d0
    dc = 0d0
    ec = 0d0
    mc = 0d0
    vc = 0d0
    ffc = 0d0
    aac = 0d0
    alc = 0d0
    auc = 0d0
    ds = 0d0
    temp_dc = 0d0
    temp_fc = 0d0
    temp_vc = 0d0
    yc = 0d0
    aps = 0d0
    bps = 0d0
    cps = 0d0
    dps = 0d0
    eps = 0d0

    DO i=1, nn
        ds(i) = s(i+1)-s(i) !Length of segment i
    ENDDO


    !Now define the entries in the matrices: AM = BV and CM+DV = F
    DO i=2, nn
        aac(i)  = (4d0)*(ds(i)+ds(i-1))
        bc(i,i) = (-1d0)*(ds(i)**(-1d0)+ds(i-1)**(-1d0))
        cc(i,i) = (-8d0/15d0)*((ds(i))**(3d0)+(ds(i-1))**(3d0))
        dc(i,i) = (2d0/3d0)*(ds(i)+ds(i-1))
        ffc(i)  = (1d0/ds(i))*(p(i+1)-p(i))-(1d0/ds(i-1))*(p(i)-p(i-1))
    ENDDO

    DO i=1, nn
        auc(i)    = 2d0*ds(i)
        alc(i)    = 2d0*ds(i)
        bc(i,i+1) = ds(i)**(-1d0)
        bc(i+1,i) = ds(i)**(-1d0)
        cc(i,i+1) = (-7d0/15d0)*(ds(i)**(3d0))
        cc(i+1,i) = (-7d0/15d0)*(ds(i)**(3d0))
        dc(i,i+1) = (1d0/3d0)*ds(i)
        dc(i+1,i) = (1d0/3d0)*ds(i)

    ENDDO

    aac(1)        = 4d0*ds(1)
    aac(nn+1)     = 4d0*ds(nn)
    bc(1,1)       = (-1d0/ds(1))
    bc(nn+1,nn+1) = (-1d0/ds(nn))
    cc(1,1)       = (-8d0*(ds(1)**(3d0))/15d0)
    cc(nn+1,nn+1) = (-8d0*(ds(nn)**(3d0))/15d0)
    dc(1,1)       = (2d0*ds(1)/3d0)
    dc(nn+1,nn+1) = (2d0*ds(nn)/3d0)
    ffc(1)        = (-1d0/ds(1))*(p(1)-p(2))
    ffc(nn+1)     = (1d0/ds(nn))*(p(nn)-p(nn+1))


    !Now solve system using tridiagonal solver from Lapack.
    CALL DGTSV(nn+1,nn+1,alc,aac,auc,bc,nn+1,INFO)


    ec = bc

    !Lapack gives E, then M=EV and (CE+D)V=F. So now find V=(CE+D)^(-1)*F
    !Use BLAS for matrix manipulations, i.e. to get CE+D

    CALL DGEMM('N','N',nn+1,nn+1,nn+1,1d0,cc,nn+1,ec,nn+1,1d0,dc,nn+1)

    !Now we have d= CE+D
    !Now solve V=(CE+D)^(-1)*F.

    temp_fc = ffc
    temp_dc = dc

    CALL DGESV(nn+1,1,temp_dc,nn+1,IPIVc,temp_fc,nn+1,INFO2)!This solves (CE+D)v=dv=f.

    dps=temp_fc

    CALL DGEMV('N',nn+1,nn+1,1d0,ec,nn+1,dps,1,0d0,yc,1)!This solves m=ev.

    bps = yc

    !We now calculate the coefficients of the spline function in terms of mm and vv.


    DO i=1,(nn)
        aps(i) = (1d0/(5d0*ds(i)))*(bps(i+1)-bps(i))
        cps(i) = (1d0/(3d0*ds(i)))*(dps(i+1)-dps(i))-((2d0*ds(i))/3d0)*(bps(i+1)+2d0*bps(i))
        eps(i) = (1d0/ds(i))*(p(i+1)-p(i))-(ds(i)/3d0)*(dps(i+1)+2d0*dps(i))+&
            ((ds(i)**(3d0))/15d0)*(7d0*bps(i+1)+8d0*bps(i))
    ENDDO

    cps(nn+1) = 10d0*aps(nn)*(ds(nn)**(2d0))+4d0*bps(nn)*ds(nn)+cps(nn)
    eps(nn+1) = 5d0*aps(nn)*(ds(nn)**4d0)+4d0*bps(nn)*(ds(nn)**3d0)+&
        3d0*cps(nn)*(ds(nn)**2d0)+2d0*dps(nn)*ds(nn)+eps(nn)

    RETURN
END SUBROUTINE


!**************************************************************************************************

SUBROUTINE Quintic_periodic_parameterised_arclength(N, aps, bps, cps, dps, eps, x, s)  ! FOR R AND Z
    IMPLICIT NONE
        !Periodic quintic spline parameterisation by arclength

    INTEGER                             :: i,N,INFO2
    INTEGER, DIMENSION(N)               :: IPIV

    DOUBLE PRECISION, DIMENSION(N,N)    :: a, b, c, d, e, temp_d
    DOUBLE PRECISION, DIMENSION(N)      :: m, v, ff, temp_f, temp_v, y
    DOUBLE PRECISION, DIMENSION(N)      :: ds
    DOUBLE PRECISION, DIMENSION(N+1)    :: x,s,aps,bps,cps,dps,eps


    !Initialise variables.
    a = 0d0
    b = 0d0
    c = 0d0
    d = 0d0
    e = 0d0
    m = 0d0
    v = 0d0
    ff = 0d0
    ds = 0d0
    temp_d = 0d0
    temp_f = 0d0
    temp_v = 0d0
    y = 0d0
    aps = 0d0
    bps = 0d0
    cps = 0d0
    dps = 0d0
    eps = 0d0

    DO i=1, N
        ds(i) = s(i+1)-s(i) !Length of segment i
    ENDDO

    !Now define the entries in the matrices: AM = BV and CM+DV = F
    DO i=2, N
        a(i,i) = (4d0)*(ds(i) + ds(i-1))
        b(i,i) = (-1d0)*(ds(i)**(-1d0) + ds(i-1)**(-1d0))
        c(i,i) = (-8d0/15d0)*((ds(i))**(3d0) + (ds(i-1))**(3d0))
        d(i,i) = (2d0/3d0)*(ds(i) + ds(i-1))
    ENDDO

    a(1,1) = (4d0)*(ds(1) + ds(N))
    b(1,1) = (-1d0)*(ds(1)**(-1d0) + ds(N)**(-1d0))
    c(1,1) = (-8d0/15d0)*((ds(1))**(3d0) + (ds(N))**(3d0))
    d(1,1) = (2d0/3d0)*(ds(1) + ds(N))

    DO i=2,(N-1)
        ff(i) = (1d0/ds(i))*(x(i+1)-x(i)) - (1d0/ds(i-1))*(x(i)-x(i-1))
    ENDDO

    DO i=1, (N-1)
        a(i,i+1) = 2d0*ds(i)
        a(i+1,i) = a(i,i+1)
        b(i,i+1) = ds(i)**(-1d0)
        b(i+1,i) = b(i,i+1)
        c(i,i+1) = (-7d0/15d0)*(ds(i)**(3d0))
        c(i+1,i) = c(i,i+1)
        d(i,i+1) = (1d0/3d0)*ds(i)
        d(i+1,i) = d(i,i+1)

    ENDDO

    !For the periodic spline we have extra terms in the corners.
    a(1,N) = 2d0*ds(N)
    a(N,1) = a(1,N)
    b(1,N) = ds(N)**(-1d0)
    b(N,1) = b(1,N)
    c(1,N) = (-7d0/15d0)*(ds(N)**(3d0))
    c(N,1) = c(1,N)
    d(1,N) = (1d0/3d0)*ds(N)
    d(N,1) = d(1,N)
    ff(1) = (1d0/ds(1))*(x(2)-x(1)) - (1d0/ds(N))*(x(1)-x(N))
    ff(N) = (1d0/ds(N))*(x(1)-x(N)) - (1d0/ds(N-1))*(x(N) - x(N-1))


    !Now solve AE=B using
    !CALL DGESV(N,N,a,N,IPIV,b,N,INFO)
    !CALL GaussJ(a,N,b)
    CALL periodic_thomas(N,a,b,e)
    !e = b

    !Lapack gives E, then M=EV and (CE+D)V=F. So now find V=(CE+D)^(-1)*F
    !Use BLAS for matrix manipulations, i.e. to get CE+D

    CALL DGEMM('N','N',N,N,N,1d0,c,N,e,N,1d0,d,N)

    !Now we have d= CE+D
    !Now solve V=(CE+D)^(-1)*F.

    temp_f = ff
    temp_d = d

    CALL DGESV(N,1,temp_d,N,IPIV,temp_f,N,INFO2)!This solves (CE+D)v=dv=f.

    v=temp_f

    CALL DGEMV('N',N,N,1d0,e,N,v,1,0,y,1)!This solves m=ev.

    m = y

    DO i=1,N
        bps(i) = m(i)
        dps(i) = v(i)
    ENDDO

    bps(N+1) = bps(1)
    dps(N+1) = dps(1)

    DO i = 1,(N)
        aps(i) = (1d0/(5d0*ds(i)))*(bps(i+1)-bps(i))
        cps(i) = (1d0/(3d0*ds(i)))*(dps(i+1)-dps(i))-(2d0*ds(i)/3d0)*(bps(i+1)+2d0*bps(i))
        eps(i) = (1d0/ds(i))*(x(i+1)-x(i))-(ds(i)/3d0)*(dps(i+1)+2d0*dps(i))+&
            ((ds(i)**(3d0))/15d0)*(7d0*bps(i+1)+8d0*bps(i))
    ENDDO
    aps(N+1) = aps(1)
    cps(N+1) = cps(1)
    eps(N+1) = eps(1)
    !aps(N) = (1d0/(5d0*ds(N)))*(bps(1)-bps(N))
    !cps(N) = (1d0/(3d0*ds(N)))*(dps(1)-dps(N))-((2d0*ds(N))/3d0)*(bps(1)+2d0*bps(N))
    !eps(N) = (1d0/ds(N))*(x(1)-x(N))-(ds(N)/3d0)*(dps(1)+2d0*dps(N))+&
     !        ((ds(N)**(3d0))/15d0)*(7d0*bps(1)+8d0*bps(N))


    RETURN
END SUBROUTINE

!****************************************************************************************************

SUBROUTINE Quintic_periodic_phi_parameterised_arclength(N, aps, bps, cps, dps, eps, x, s) ! FOR PHI
    IMPLICIT NONE
        !Periodic quintic spline  parameterisation by arclength

    INTEGER                                 :: i,N,INFO2
    INTEGER, DIMENSION(N)                   :: IPIV

    DOUBLE PRECISION, DIMENSION(N,N)        :: a, b, c, d, e, temp_d
    DOUBLE PRECISION, DIMENSION(N)          :: m, v, ff, temp_f, temp_v, y
    DOUBLE PRECISION, DIMENSION(N)          :: ds
    DOUBLE PRECISION, DIMENSION(N+1)        :: x, s, aps, bps, cps, dps, eps



    !Initialise variables.
    a = 0d0
    b = 0d0
    c = 0d0
    d = 0d0
    e = 0d0
    m = 0d0
    v = 0d0
    ff = 0d0
    ds = 0d0
    temp_d = 0d0
    temp_f = 0d0
    temp_v = 0d0
    y = 0d0
    aps = 0d0
    bps = 0d0
    cps = 0d0
    dps = 0d0
    eps = 0d0

    DO i=1, N
        ds(i) = s(i+1)-s(i) !Length of segment i
    ENDDO

    !Now define the entries in the matrices: AM = BV and CM+DV = F
    DO i=2, N
        a(i,i) = (4d0)*(ds(i) + ds(i-1))
        b(i,i) = (-1d0)*(ds(i)**(-1d0) + ds(i-1)**(-1d0))
        c(i,i) = (-8d0/15d0)*((ds(i))**(3d0) + (ds(i-1))**(3d0))
        d(i,i) = (2d0/3d0)*(ds(i) + ds(i-1))
    ENDDO

    a(1,1) = (4d0)*(ds(1) + ds(N))
    b(1,1) = (-1d0)*(ds(1)**(-1d0) + ds(N)**(-1d0))
    c(1,1) = (-8d0/15d0)*((ds(1))**(3d0) + (ds(N))**(3d0))
    d(1,1) = (2d0/3d0)*(ds(1) + ds(N))

    DO i=2,(N-1)
        ff(i) = (1d0/ds(i))*(x(i+1)-x(i)) - (1d0/ds(i-1))*(x(i)-x(i-1))
    ENDDO

    DO i=1, (N-1)
        a(i,i+1) = 2d0*ds(i)
        a(i+1,i) = a(i,i+1)
        b(i,i+1) = ds(i)**(-1d0)
        b(i+1,i) = b(i,i+1)
        c(i,i+1) = (-7d0/15d0)*(ds(i)**(3d0))
        c(i+1,i) = c(i,i+1)
        d(i,i+1) = (1d0/3d0)*ds(i)
        d(i+1,i) = d(i,i+1)

    ENDDO

    !For the periodic spline we have extra terms in the corners.
    a(1,N) = 2d0*ds(N)
    a(N,1) = a(1,N)
    b(1,N) = ds(N)**(-1d0)
    b(N,1) = b(1,N)
    c(1,N) = (-7d0/15d0)*(ds(N)**(3d0))
    c(N,1) = c(1,N)
    d(1,N) = (1d0/3d0)*ds(N)
    d(N,1) = d(1,N)
    ff(1) = (1d0/ds(1))*(x(2)-x(1)) - (1d0/ds(N))*(x(N+1)-x(N))
    ff(N) = (1d0/ds(N))*(x(N+1)-x(N)) - (1d0/ds(N-1))*(x(N) - x(N-1))


    !Now solve AE=B using Gaussian Elimination.
    !CALL DGESV(N,N,a,N,IPIV,b,N,INFO)
    !CALL GaussJ(a,N,b)
    CALL periodic_thomas(N,a,b,e)
    !e = b

    !Lapack gives E, then M=EV and (CE+D)V=F. So now find V=(CE+D)^(-1)*F
    !Use BLAS for matrix manipulations, i.e. to get CE+D

    CALL DGEMM('N','N',N,N,N,1d0,c,N,e,N,1d0,d,N)

    !Now we have d= CE+D
    !Now solve V=(CE+D)^(-1)*F.

    temp_f = ff
    temp_d = d

    CALL DGESV(N,1,temp_d,N,IPIV,temp_f,N,INFO2)!This solves (CE+D)v=dv=f.

    v=temp_f

    CALL DGEMV('N',N,N,1d0,e,N,v,1,0,y,1)!This solves m=ev.

    DO i=1,N
        bps(i) = y(i)
        dps(i) = v(i)
    ENDDO

    bps(N+1) = bps(1)
    dps(N+1) = dps(1)

    DO i = 1,(N)
        aps(i) = (1d0/(5d0*ds(i)))*(bps(i+1)-bps(i))
        cps(i) = (1d0/(3d0*ds(i)))*(dps(i+1)-dps(i))-((2d0*ds(i))/3d0)*(bps(i+1)+2d0*bps(i))
        eps(i) = (1d0/ds(i))*(x(i+1)-x(i))-(ds(i)/3d0)*(dps(i+1)+2d0*dps(i))+&
            ((ds(i)**(3d0))/15d0)*(7d0*bps(i+1)+8d0*bps(i))
    ENDDO
    aps(N+1) = aps(1)
    cps(N+1) = cps(1)
    eps(N+1) = eps(1)
    !aps(N) = (1d0/(5d0*ds(N)))*(bps(1)-bps(N))
    !cps(N) = (1d0/(3d0*ds(N)))*(dps(1)-dps(N))-((2d0*ds(N))/3d0)*(bps(1)+2d0*bps(N))
    !eps(N) = (1d0/ds(N))*(x(N+1)-x(N))-(ds(N)/3d0)*(dps(1)+2d0*dps(N))+&
    !         ((ds(N)**(3d0))/15d0)*(7d0*bps(1)+8d0*bps(N))


    RETURN
END SUBROUTINE

!****************************************************************************************************

SUBROUTINE Quintic_periodic(N, x, aps, bps, cps, dps, eps)  ! FOR R AND Z
    IMPLICIT NONE
        !Periodic quintic spline with parameterisation [0,1] over each segment

    INTEGER                             :: i,N,INFO2
    INTEGER, DIMENSION(N)               :: IPIV

    DOUBLE PRECISION, DIMENSION(N,N)    :: a, b, c, d, e, temp_d
    DOUBLE PRECISION, DIMENSION(N)      :: m, v, ff, temp_f, temp_v, y
    DOUBLE PRECISION, DIMENSION(N+1)    :: x, aps, bps, cps, dps ,eps


    !Initialise variables.
    a = 0d0
    b = 0d0
    c = 0d0
    d = 0d0
    e = 0d0
    m = 0d0
    v = 0d0
    ff = 0d0
    temp_d = 0d0
    temp_f = 0d0
    temp_v = 0d0
    y = 0d0
    aps = 0d0
    bps = 0d0
    cps = 0d0
    dps = 0d0
    eps = 0d0

    !Now define the entries in the matrices: AM = BV and CM+DV = F
    DO i=1, N
        a(i,i) = (8d0)
        b(i,i) = (-2d0)
        c(i,i) = (-16d0/15d0)
        d(i,i) = (4d0/3d0)
    ENDDO


    DO i=2,(N-1)
        ff(i) = (x(i+1)-x(i)) - (x(i)-x(i-1))
    ENDDO

    DO i=1, (N-1)
        a(i,i+1) = 2d0
        a(i+1,i) = a(i,i+1)
        b(i,i+1) = 1d0
        b(i+1,i) = b(i,i+1)
        c(i,i+1) = -7d0/15d0
        c(i+1,i) = c(i,i+1)
        d(i,i+1) = 1d0/3d0
        d(i+1,i) = d(i,i+1)

    ENDDO

    !For the periodic spline we have extra terms in the corners.
    a(1,N) = 2d0
    a(N,1) = a(1,N)
    b(1,N) = 1d0
    b(N,1) = b(1,N)
    c(1,N) = -7d0/15d0
    c(N,1) = c(1,N)
    d(1,N) = 1d0/3d0
    d(N,1) = d(1,N)
    ff(1) = (x(2)-x(1)) - (x(1)-x(N))
    ff(N) = (x(1)-x(N)) - (x(N) - x(N-1))


    !Now solve AE=B using Gaussian Elimination.
    !CALL DGESV(N,N,a,N,IPIV,b,N,INFO)
    !CALL GaussJ(a,N,b)
    CALL periodic_thomas(N,a,b,e)
    !e=b

    !Lapack gives E, then M=EV and (CE+D)V=F. So now find V=(CE+D)^(-1)*F
    !Use BLAS for matrix manipulations, i.e. to get CE+D

    CALL DGEMM('N','N',N,N,N,1d0,c,N,e,N,1d0,d,N)

    !Now we have d= CE+D
    !Now solve V=(CE+D)^(-1)*F.

    temp_f = ff
    temp_d = d

    CALL DGESV(N,1,temp_d,N,IPIV,temp_f,N,INFO2)!This solves (CE+D)v=dv=f.

    v=temp_f

    CALL DGEMV('N',N,N,1d0,e,N,v,1,0,y,1)!This solves m=ev.

    m = y

    DO i=1,N
        bps(i) = m(i)
        dps(i) = v(i)
    ENDDO

    bps(N+1) = bps(1)
    dps(N+1) = dps(1)

    DO i = 1,(N)
        aps(i) = (1d0/(5d0))*(bps(i+1)-bps(i))
        cps(i) = (1d0/(3d0))*(dps(i+1)-dps(i))-((2d0)/3d0)*(bps(i+1)+2d0*bps(i))
        eps(i) = (1d0)*(x(i+1)-x(i))-(1d0/3d0)*(dps(i+1)+2d0*dps(i))+&
            ((1d0)/15d0)*(7d0*bps(i+1)+8d0*bps(i))
    ENDDO
    aps(N+1) = aps(1)
    cps(N+1) = cps(1)
    eps(N+1) = eps(1)

    !aps(N) = (1d0/(5d0))*(bps(1)-bps(N))
    !cps(N) = (1d0/(3d0))*(dps(1)-dps(N))-((2d0)/3d0)*(bps(1)+2d0*bps(N))
    !eps(N) = (1d0)*(x(1)-x(N))-(1d0/3d0)*(dps(1)+2d0*dps(N))+&
    !         ((1d0)/15d0)*(7d0*bps(1)+8d0*bps(N))



    RETURN
END SUBROUTINE


SUBROUTINE periodic_thomas(n,a,f,output)

    implicit none

    integer                  :: i, n
    double precision         :: a(n,n), f(n), aa(n,n), u(n), v(n),&
        al(n), am(n), au(n), y(n), q(n), &
        vy(n), vq(n), output(n)
    double precision         :: ysum, qsum

    aa = 0d0
    output = 0d0
    u = 0d0
    v = 0d0

    aa = a
    aa(1,1) = 2d0*a(1,1)
    aa(n,n) = a(1,n)*a(n,1)/a(1,1) + a(n,n)
    u(1) = -1d0*a(1,1)
    u(n) = a(n,1)
    v(1) = 1d0
    v(n) = -1d0*a(1,n)/a(1,1)
    DO i=1,(n-1)
        al(i) = aa(i+1,i)
        au(i) = aa(i,i+1)
    ENDDO
    DO i=1,n
        am(i) = aa(i,i)
    ENDDO

    CALL tridiag(n,al,am,au,f,y)
    CALL tridiag(n,al,am,au,u,q)

    DO i=1,n
        vy(i) = v(i)*y(i)
        vq(i) = v(i)*q(i)
    ENDDO

    ysum = sum(vy)
    qsum = sum(vq)

    DO i=1,n
        output(i) = y(i) - ( ysum / (1+qsum) )*q(i)
    ENDDO


END SUBROUTINE



! Standard integration over segement j, using Gaussian quadrature.
SUBROUTINE gauss_torus(ri, zi, rc1, zc1, rc2, zc2, Ic)
    implicit none
    double precision    :: Ic, gi(6), w(6), rrc, zzc, rc2, zc2,&
        zi, ri, rc1, zc1, drrc, dzzc, Cc, Sc, Rc, Qc, Pc, mc, Kc, Ec,&
        dsc, ssc


    integer            :: l

    zc2 = zc2              !Variable not used

    Ic = 0d0

    !Perform Gaussian quadrature summations over l
    do 1 l = 1, 6

        gi(1)=-0.93246951420315202781
        gi(2)=-0.66120938646626451366
        gi(3)=-0.23861918608319690863     !6-gauss points
        gi(4)=0.23861918608319690863
        gi(5)=0.66120938646626451366
        gi(6)=0.93246951420315202781

        w(1)=0.17132449237917034504
        w(2)=0.36076157304813860757
        w(3)=0.46791393457269104739       !6-gauss wieghts
        w(4)=0.46791393457269104739
        w(5)=0.36076157304813860757
        w(6)=0.17132449237917034504


        ! cut surface
        dsc = rc2 - rc1
        ssc = ((rc2 - rc1)/2d0)*gi(l) + (rc2 + rc1)/2d0

        rrc = ssc
        zzc = zc1

        drrc = 1d0
        dzzc = 0d0

        Cc = dsqrt((rrc + ri)**2 + (zzc - zi)**2)

        !Calculate values of elliptic integrals (using polynomial apprx.)
        call elliptic(rrc, zzc, ri, zi, mc, Kc, Ec, Pc, Qc, Rc, Sc)

        Ic = Ic - (4d0*rrc/(Cc**3))*((dzzc*(rrc + ri) - drrc*(zzc - zi)&
            - ri*dzzc*(2d0/mc))*(Ec/(1d0 - mc)) + (2d0/mc)*dzzc*ri*Kc)*w(l)


1   continue

    Ic = dsc*0.5d0*Ic

    return
END SUBROUTINE


SUBROUTINE SURFACE_torus(rr, zz, pphi, ss, nnr,  nnz, ssr, ssz,&
    nnp, nn_order,delPhi,&
    ttang_vel, ccurvature, ddphi2_ds2, ddphi_dn)

    implicit none
    integer          :: nnp, i, nn_order, m, nn_end

    double precision :: rr(nnp + 1), zz(nnp + 1), pphi(nnp + 1),&
        nnr(nnp + 1), nnz(nnp + 1), ssr(nnp + 1), ssz(nnp + 1),&
        dr(nnp + 1), dz(nnp + 1), dr2(nnp + 1), dz2(nnp + 1),&
        ddphi2_ds2(nnp + 1), ccurvature(nnp + 1), ttang_vel(nnp + 1), JJ,&
        delPhi,ddphi_dn(nnp + 1),&
        ss(nnp + 1), pphi_end(nnp + 1 + nn_order),&
        rr_end(nnp + 1 + nn_order), zz_end(nnp + 1 + nn_order),&
        ss_end(nnp + 1 + nn_order)

    ccurvature = 0d0
    ddphi_dn = ddphi_dn
    ttang_vel = ttang_vel

    !nn_order is order of scheme (has to be even)

    m = nn_order/2
    nn_end = nnp + nn_order

    do 10 i = 1, (nnp + 1)

        pphi_end(m + i) = pphi(i)
        rr_end(m + i) = rr(i)
        zz_end(m + i) = zz(i)
        ss_end(m + i) = ss(i)

10  continue

    ! This loop extends variables r,z,phi,s into negative plane so derivative can be
    ! taken on and near the axis of symmetry, for closed bubble nodes:


    do 11 i = 1, m
        pphi_end(i) = pphi(nnp + i - m) - delPhi
        zz_end(i) = zz(nnp + i - m)
        rr_end(i) = rr(nnp + i - m)
        ss_end(i) = -(ss(nnp + 1) - ss(nnp + i - m))

        pphi_end(nnp + 1 + m + i) = pphi(i+1) + delPhi
        zz_end(nnp + 1 + m + i) = zz(i+1)
        rr_end(nnp + 1 + m + i) = rr(i+1)
        ss_end(nnp + 1 + m + i) = ss(nnp + 1) + ss(i+1)

11  continue


    !Calc. first derivative of phi to give tang. velocity
    !call first_deriv(ss_end, pphi_end, ttang_vel, nn_end, nn_order)
    !Calc. second derivative of phi ..
    call second_deriv(ss_end, pphi_end, ddphi2_ds2, nn_end, nn_order)

    !do i = 1, (nnp + 1)

    !  ttang_end(m + i) = ttang_vel(i)

    !enddo

    ! do i = 1, m

    ! ttang_end(i) = ttang_vel(nnp + i - m)
    !  ttang_end(nnp + 1 + m + i) = ttang_vel(i+1)

    ! enddo

    ! call first_deriv(ss_end, ttang_end, ddphi2_ds2, nn_end, nn_order)
    !Calc. first deriv of r, dr
    call first_deriv(ss_end, rr_end, dr, nn_end, nn_order)
    !Calc. second deriv of r, dr2
    call second_deriv(ss_end, rr_end, dr2, nn_end, nn_order)

    !Calc. first deriv of z, dz
    call first_deriv(ss_end, zz_end, dz, nn_end, nn_order)
    !Calc. second deriv of z, dz2
    call second_deriv(ss_end, zz_end, dz2, nn_end, nn_order)


    !! calculate the curvature and normal and tangent vectors for the bubble

    do 1 i = 1, (nnp + 1)
          !Calc. in-plane curvature
        ccurvature(i) =  -(dr(i)*dz2(i) - dr2(i)*dz(i))/((dr(i)**2 + dz(i)**2)**(3d0/2d0))
        ! Calc. Jacobian
        JJ = dsqrt(dz(i)**2 + dr(i)**2)
        ! Calc. normal and tangential vectors
        nnr(i) =   (1d0/JJ)*dz(i)
        nnz(i) =   -(1d0/JJ)*dr(i)
        ssr(i) =   (1d0/JJ)*dr(i)
        ssz(i) =   (1d0/JJ)*dz(i)
1   continue

    return
END SUBROUTINE

SUBROUTINE SURFACE_REM_torus(rr, zz, pphi, ss, nnr,  nnz, ssr, ssz,&
    nnp, nn_order,delPhi,&
    ttang_vel, ccurvature, ddphi2_ds2, ddphi_dn)

    implicit none
    integer          :: nnp, i, nn_order, m, nn_end

    double precision :: rr(nnp + 1), zz(nnp + 1), pphi(nnp + 1),&
        nnr(nnp + 1), nnz(nnp + 1), ssr(nnp + 1), ssz(nnp + 1),&
        dr(nnp + 1), dz(nnp + 1), dr2(nnp + 1), dz2(nnp + 1),&
        ddphi2_ds2(nnp + 1), ccurvature(nnp + 1), ttang_vel(nnp + 1), JJ,&
        delPhi,ddphi_dn(nnp + 1),&
        ss(nnp + 1), pphi_end(nnp + 1 + nn_order),&
        rr_end(nnp + 1 + nn_order), zz_end(nnp + 1 + nn_order), ss_end(nnp + 1 + nn_order)

    ccurvature = 0d0
    delPhi = delPhi
    ddphi_dn = ddphi_dn

    !nn_order is order of scheme (has to be even)

    m = nn_order/2
    nn_end = nnp + nn_order

    do 10 i = 1, (nnp + 1)

        pphi_end(m + i) = pphi(i)
        rr_end(m + i) = rr(i)
        zz_end(m + i) = zz(i)
        ss_end(m + i) = ss(i)

10  continue

    ! This loop extends variables r,z,phi,s into negative plane so derivative can be
    ! taken on and near the axis of symmetry, for closed bubble nodes:

    do 11 i = 1, m
        pphi_end(i) = pphi(nnp + i - m)
        zz_end(i) = zz(nnp + i - m)
        rr_end(i) = rr(nnp + i - m)
        ss_end(i) = -(ss(nnp + 1) - ss(nnp + i - m))

        pphi_end(nnp + 1 + m + i) = pphi(i+1)
        zz_end(nnp + 1 + m + i) = zz(i+1)
        rr_end(nnp + 1 + m + i) = rr(i+1)
        ss_end(nnp + 1 + m + i) = ss(nnp + 1) + ss(i+1)

11  continue


    !Calc. first derivative of phi to give tang. velocity
    call first_deriv(ss_end, pphi_end, ttang_vel, nn_end, nn_order)
    !Calc. second derivative of phi ..
    call second_deriv(ss_end, pphi_end, ddphi2_ds2, nn_end, nn_order)

    !Calc. first deriv of r, dr
    call first_deriv(ss_end, rr_end, dr, nn_end, nn_order)
    !Calc. second deriv of r, dr2
    call second_deriv(ss_end, rr_end, dr2, nn_end, nn_order)

    !Calc. first deriv of z, dz
    call first_deriv(ss_end, zz_end, dz, nn_end, nn_order)
    !Calc. second deriv of z, dz2
    call second_deriv(ss_end, zz_end, dz2, nn_end, nn_order)


    !! calculate the curvature and normal and tangent vectors for the bubble

    do 1 i = 1, (nnp + 1)
           !Calc. in-plane curvature
        ccurvature(i) =  -(dr(i)*dz2(i) - dr2(i)*dz(i))/((dr(i)**2 + dz(i)**2)**(3d0/2d0))
        ! Calc. Jacobian
        JJ = dsqrt(dz(i)**2 + dr(i)**2)
        ! Calc. normal and tangential vectors
        nnr(i) =   (1d0/JJ)*dz(i)
        nnz(i) =   -(1d0/JJ)*dr(i)
        ssr(i) =   (1d0/JJ)*dr(i)
        ssz(i) =   (1d0/JJ)*dz(i)
1   continue

    return
END SUBROUTINE


!Integration when collocation point i on axis
SUBROUTINE gaussaxis_2(r1,z1,zi,&
    aaphi, bbphi, ccphi, ddphi, eephi,&
    aar, bbr, ccr, ddr, eer,&
    aaz, bbz, ccz, ddz, eez,&
    aadphidn, bbdphidn, ccdphidn, dddphidn, eedphidn,&
    II1,III,pphi, dphidn, IIIa, s2, s1)


    implicit none
    double precision :: II1, III, gi(6), w(6),&
        rr, zz, r1, z1, drr, dzz, J, C,&
        zi, pi, aar, bbr, ccr, ddr, eer, aaz, bbz, ccz, ddz, eez,&
        aadphidn, bbdphidn, ccdphidn, dddphidn, eedphidn, dphidn, normal_vel,&
        aaphi, bbphi, ccphi, ddphi, eephi, pphi, IIIa, s2, s1, dds, ppphi, ss

    integer          :: l


    II1 = 0d0
    IIIa  = 0d0
    III = 0d0

    do 1 l = 1, 6

        gi(1)=-0.93246951420315202781
        gi(2)=-0.66120938646626451366
        gi(3)=-0.23861918608319690863                      !6-gauss points
        gi(4)=0.23861918608319690863
        gi(5)=0.66120938646626451366
        gi(6)=0.93246951420315202781

        w(1)=0.17132449237917034504
        w(2)=0.36076157304813860757
        w(3)=0.46791393457269104739                       !6-gauss wieghts
        w(4)=0.46791393457269104739
        w(5)=0.36076157304813860757
        w(6)=0.17132449237917034504

        pi = 4d0*datan(1d0)

        dds = s2 - s1
        ss = ((s2 - s1)/2d0)*gi(l) + (s2 + s1)/2d0

        rr = aar*(ss - s1)**5 + bbr*(ss - s1)**4 + ccr*(ss - s1)**3&
            + ddr*(ss -s1)**2 + eer*(ss - s1) + r1
        zz = aaz*(ss - s1)**5 + bbz*(ss - s1)**4 + ccz*(ss - s1)**3&
            + ddz*(ss -s1)**2 + eez*(ss -s1) + z1
        ppphi = (aaphi*(ss - s1)**5 + bbphi*(ss - s1)**4 + ccphi*(ss - s1)**3 &
            + ddphi*(ss -s1)**2 + eephi*(ss -s1) + pphi)
        normal_vel = aadphidn*(ss - s1)**5 + bbdphidn*(ss - s1)**4 + ccdphidn*(ss - s1)**3 +&
            dddphidn*(ss - s1)**2 + eedphidn*(ss -s1) + dphidn !dphi_dn spline

        drr = 5d0*aar*(ss - s1)**4 + 4d0*bbr*(ss - s1)**3 + 3d0*ccr*(ss - s1)**2 +&
            2d0*ddr*(ss - s1) + eer !r derivative
        dzz = 5d0*aaz*(ss - s1)**4 + 4d0*bbz*(ss - s1)**3 + 3d0*ccz*(ss - s1)**2 +&
            2d0*ddz*(ss - s1) + eez !r derivative

        J = 1d0!!dsqrt(dzz**2+drr**2)

        C = dsqrt((rr)**2+(zz-zi)**2)


        II1 = II1 + normal_vel*(2d0*pi*J*rr/C)*w(l)

        III = III + ppphi*&
            (2d0*pi*rr/C**3)*(dzz*(rr) - drr*(zz - zi))*w(l)

        IIIa = IIIa + (2d0*pi*rr/C**3)*(dzz*(rr) - drr*(zz - zi))*w(l)


1   continue

    II1 = dds*0.5d0*II1
    III = dds*0.5d0*III
    IIIa = dds*0.5d0*IIIa

    return
END SUBROUTINE



SUBROUTINE gaussaxis_jet(r1,z1,zi,&
    aaphi, bbphi, ccphi, ddphi, eephi,&
    aar, bbr, ccr, ddr, eer,&
    aaz, bbz, ccz, ddz, eez,&
    adphidn, bdphidn, cdphidn, ddphidn, edphidn,&
    II1, III, pphi, HP, IIIa, s2, s1)



    implicit none
    double precision :: II1, III, gi(6), w(6),&
        rr, zz, r1, z1, drr, dzz, J, C,&
        zi, pi, aar, bbr, ccr, ddr, eer, aaz, bbz, ccz, ddz, eez,&
        aaphi, bbphi, ccphi, ddphi, eephi, pphi, IIIa, s2, s1,&
        dds, ppphi, ss, HP, adphidn, bdphidn, cdphidn, ddphidn, edphidn,&
        normal_vel

    integer          :: l


    II1 = 0d0
    IIIa  = 0d0
    III = 0d0

    do 1 l = 1, 6

        gi(1)=-0.93246951420315202781
        gi(2)=-0.66120938646626451366
        gi(3)=-0.23861918608319690863                      !6-gauss points
        gi(4)=0.23861918608319690863
        gi(5)=0.66120938646626451366
        gi(6)=0.93246951420315202781

        w(1)=0.17132449237917034504
        w(2)=0.36076157304813860757
        w(3)=0.46791393457269104739                       !6-gauss wieghts
        w(4)=0.46791393457269104739
        w(5)=0.36076157304813860757
        w(6)=0.17132449237917034504

        pi = 4d0*datan(1d0)

        dds = s2 - s1
        ss = ((s2 - s1)/2d0)*gi(l) + (s2 + s1)/2d0

        rr = aar*(ss - s1)**5 + bbr*(ss - s1)**4 + ccr*(ss - s1)**3&
            + ddr*(ss -s1)**2 + eer*(ss -s1) + r1
        zz = aaz*(ss - s1)**5 + bbz*(ss - s1)**4 + ccz*(ss - s1)**3&
            + ddz*(ss -s1)**2 + eez*(ss -s1) + z1
        ppphi = (aaphi*(ss - s1)**5 + bbphi*(ss - s1)**4 + ccphi*(ss - s1)**3 &
            + ddphi*(ss -s1)**2 + eephi*(ss -s1) + pphi)
        normal_vel = adphidn*(ss - s1)**5 + bdphidn*(ss - s1)**4 + cdphidn*(ss - s1)**3 +&
            ddphidn*(ss - s1)**2 + edphidn*(ss -s1) + HP !dphi_dn spline

        drr = 5d0*aar*(ss - s1)**4 + 4d0*bbr*(ss - s1)**3 + 3d0*ccr*(ss - s1)**2 +&
            2d0*ddr*(ss - s1) + eer !r derivative
        dzz = 5d0*aaz*(ss - s1)**4 + 4d0*bbz*(ss - s1)**3 + 3d0*ccz*(ss - s1)**2 +&
            2d0*ddz*(ss - s1) + eez !r derivative

        J = dsqrt(dzz**2+drr**2)

        C = dsqrt((rr)**2+(zz-zi)**2)

        !II1,II2,etc.. have a different form if (ri,zi) on axis of symmetry (ie. ri=0)

        II1 = II1 + normal_vel*(2d0*pi*J*rr/C)*w(l)

        III = III + ppphi*&
            (2d0*pi*rr/C**3)*(dzz*(rr) - drr*(zz - zi))*w(l)

    !IIIa = IIIa + (2d0*pi*rr/C**3)*(dzz*(rr) - drr*(zz - zi))*w(l)


1   continue

    II1 = dds*0.5d0*II1
    III = dds*0.5d0*III
    IIIa = dds*0.5d0*IIIa

    return
END SUBROUTINE



SUBROUTINE volume_gauss(r1, aar, bbr, ccr, s2, s1, Vint)

    implicit none
    double precision    :: gi(6), w(6), rr, r1,&
        aar, bbr, ccr, s2, s1, Vint, ss, dds


    integer            :: l

    Vint = 0d0

    !Perform Gaussian quadrature summations over l
    do 1 l = 1, 6

        gi(1)=-0.93246951420315202781
        gi(2)=-0.66120938646626451366
        gi(3)=-0.23861918608319690863     !6-gauss points
        gi(4)=0.23861918608319690863
        gi(5)=0.66120938646626451366
        gi(6)=0.93246951420315202781

        w(1)=0.17132449237917034504
        w(2)=0.36076157304813860757
        w(3)=0.46791393457269104739       !6-gauss wieghts
        w(4)=0.46791393457269104739
        w(5)=0.36076157304813860757
        w(6)=0.17132449237917034504

        dds = s2 - s1
        ss = ((s2 - s1)/2d0)*gi(l) + (s2 + s1)/2d0 !arclength function of gauss-point

        rr = aar*(ss - s1)**3 + bbr*(ss - s1)**2 + ccr*(ss - s1) + r1 ! r spline

        Vint = Vint + rr*w(l)


1   continue

    Vint = dds*0.5d0*Vint !integral multiplied by scaling factor due to change of variables

    return
END SUBROUTINE


!****************************************************************************
! VORTEX RING ROUTINES
!****************************************************************************



SUBROUTINE PNPOLY(PX,PY,XX,YY,N,INOUT)
    Double precision X(200),Y(200),XX(N),YY(N), PX, PY
    LOGICAL MX,MY,NX,NY
    INTEGER O
    DATA O/6/
    MAXDIM=200
    IF(N.LE.MAXDIM)GO TO 6
    WRITE(O,7)
7   FORMAT('0WARNING:',I5,' TOO GREAT FOR THIS VERSION OF PNPOLY. 1RESULTS INVALID')
    RETURN

    6 DO 1 I=1,N
        X(I)=XX(I)-PX
1       Y(I)=YY(I)-PY
        INOUT=-1
        DO 2 I=1,N
            J=1+MOD(I,N)
            MX=X(I).GE.0.0
            NX=X(J).GE.0.0
            MY=Y(I).GE.0.0
            NY=Y(J).GE.0.0
            IF(.NOT.((MY.OR.NY).AND.(MX.OR.NX)).OR.(MX.AND.NX)) GO TO 2
            IF(.NOT.(MY.AND.NY.AND.(MX.OR.NX).AND..NOT.(MX.AND.NX))) GO TO 3
            INOUT=-INOUT
            GO TO 2
3           IF((Y(I)*X(J)-X(I)*Y(J))/(X(J)-X(I))) 2,4,5
4           INOUT=0
            RETURN
5           INOUT=-INOUT
2       CONTINUE


        RETURN

    END SUBROUTINE



    SUBROUTINE trap(low_bound,high_bound,NN_trap,trap_fct,trap_approx)
        ! Approximates an integral using the trapezoidal rule. trap_fct is a vector
        ! contaning the function being approximated.
        IMPLICIT NONE

        INTEGER                                   :: NN_trap
        DOUBLE PRECISION, DIMENSION(NN_trap+1)    :: trap_fct
        DOUBLE PRECISION                          :: trap_approx, low_bound, high_bound, h

        !Initialise variables.
        trap_approx = 0d0
        h = 0d0

        h = (high_bound - low_bound)/dble(NN_trap) !Distance between points

        trap_approx = (h/2d0)*(2d0*sum(trap_fct) - trap_fct(1) - trap_fct(NN_trap+1))

        !write(*,*) 'trap_approx', trap_approx

        RETURN
    END SUBROUTINE


    SUBROUTINE int_1_2_fct(kk,N_trap,i1_fct,i2_fct)

        ! This calculates the functions of integrals 1 and 2 which are inputted into
        ! the trapezoidal rule.
        ! N = no. of nodes on bubble.
        ! N_trap is number of points used for trapezoidal rule.

        IMPLICIT NONE

        INTEGER                              :: N_trap, i
        DOUBLE PRECISION                     :: hh, kk, pi
        DOUBLE PRECISION,DIMENSION(N_trap+1) :: i1_fct, i2_fct, theta, cos_vect



        !Initialise variables:
        i1_fct = 0d0
        i2_fct = 0d0
        hh = 0d0
        theta = 0d0
        pi = 4d0*datan(1d0)


        hh = pi / dble( N_trap )           !Distance between trapezoidal rule nodes.

        DO i = 1, (N_trap + 1)
            theta(i) = (i-1)*hh
            cos_vect(i) = cos( dble( theta(i) ) )
            i2_fct(i) = ( 1d0 - kk*cos_vect(i) )**(-3d0/2d0)
            i1_fct(i) = cos_vect(i)*i2_fct(i)
        ENDDO


        RETURN
    END SUBROUTINE

    SUBROUTINE int_1_2_fct2(kk,N_trap,i1_fct,i2_fct)

        ! This calculates the functions of integrals 1 and 2 which are inputted into
        ! the trapezoidal rule.
        ! N = no. of nodes on bubble.
        ! N_trap is number of points used for trapezoidal rule.

        IMPLICIT NONE

        INTEGER                              :: N_trap, i
        DOUBLE PRECISION                     :: hh, kk, pi
        DOUBLE PRECISION,DIMENSION(N_trap+1) :: i1_fct, i2_fct, theta, cos_vect
        DOUBLE PRECISION,DIMENSION(6)        :: gi, wt


        !Initialise variables:
        i1_fct = 0d0
        i2_fct = 0d0
        hh = 0d0
        theta = 0d0
        pi = 4d0*datan(1d0)

        gi(1)=-0.93246951420315202781
        gi(2)=-0.66120938646626451366
        gi(3)=-0.23861918608319690863     !6-gauss points
        gi(4)=0.23861918608319690863
        gi(5)=0.66120938646626451366
        gi(6)=0.93246951420315202781

        wt(1)=0.17132449237917034504
        wt(2)=0.36076157304813860757
        wt(3)=0.46791393457269104739       !6-gauss wieghts
        wt(4)=0.46791393457269104739
        wt(5)=0.36076157304813860757
        wt(6)=0.17132449237917034504

        hh = pi / dble( N_trap )           !Distance between trapezoidal rule nodes.

        DO i = 1, (N_trap + 1)
            theta(i) = (pi/2d0)*gi(i) + pi/2d0
            cos_vect(i) = cos( dble( theta(i) ) )
            i2_fct(i) = ( ( 1d0 - kk*cos_vect(i) )**(-3d0/2d0) )*wt(i)
            i1_fct(i) = cos_vect(i)*i2_fct(i)
        ENDDO


        RETURN
    END SUBROUTINE


    SUBROUTINE vortpot_n1(N,N_trap,deltaPhi,rrrr,zzzz,vri,vzi,vpotential1)
        ! Subroutine for the vortex potential at the first node.
        IMPLICIT NONE


        INTEGER                                        :: N, N_trap, j
        DOUBLE PRECISION                               :: h, vri, vzi, i1_lb, i1_hb,&
            i2_lb, i2_hb, int_approx1, int_approx2,&
            pi, deltaPhi, vpotential1, temp
        DOUBLE PRECISION,DIMENSION(N_trap+1)           :: r_trap, int1_p,&
            int1_m, kkm, kkp, u_vr
        DOUBLE PRECISION,DIMENSION(N+1)                :: rrrr, zzzz
        DOUBLE PRECISION, DIMENSION(N_trap+1,N_trap+1) :: i1p, i2p, i1m, i2m

        !Initialise variables:
        pi = 4d0*datan(1d0)
        i1_lb = 0d0
        i1_hb = pi
        i2_lb = 0d0
        i2_hb = pi
        i1p = 0d0
        i2p = 0d0
        i1m = 0d0
        i2m = 0d0
        int1_p = 0d0
        int1_m = 0d0
        r_trap = 0d0
        h = 0d0
        vpotential1 = 0d0
        int_approx1 = 0d0
        temp = 0d0


        !First Integral
        !int_approx1 = (-deltaPhi/2d0)*&
        !              ( tanh( dasinh((zzzz(1) - vzi)/vri) ) +&
         !             tanh( dasinh((zzzz(1) + vzi)/vri) ) + 2d0 )


        int_approx1 = (1d0)*(deltaPhi/2d0)*&
            ( (zzzz(1)-vzi)*(vri**2d0 + (zzzz(1)-vzi)**2d0)**(-0.5d0) -&
            (zzzz(1)+vzi)*(vri**2d0 + (zzzz(1)+vzi)**2d0)**(-0.5d0)  )

        !write(*,*) 'integral 1 of node 1', int_approx1

        !Second Integral
        h = rrrr(1)/dble(N_trap)


        DO j = 1, (N_trap+1)

            r_trap(j) = dble(j-1)*h

            kkp(j) = ( 2d0*vri*r_trap(j) )/( r_trap(j)**2d0 + (zzzz(1) + vzi)**2d0 + vri**2d0 )
            kkm(j) = ( 2d0*vri*r_trap(j) )/( r_trap(j)**2d0 + (zzzz(1) - vzi)**2d0 + vri**2d0 )

            CALL int_1_2_fct( kkp(j),N_trap,i1p(j,:),i2p(j,:) )
            CALL int_1_2_fct( kkm(j),N_trap,i1m(j,:),i2m(j,:) )

            CALL trap( i1_lb,i1_hb,N_trap,i1p(j,:),int1_p(j) )
            CALL trap( i2_lb,i2_hb,N_trap,i1m(j,:),int1_m(j) )

            u_vr(j) = (1d0)*( ( ( r_trap(j)**2d0 + (zzzz(1)-vzi)**(2d0) + vri**(2d0) )**(-3d0/2d0) )&
                *(zzzz(1)-vzi)*int1_m(j) -&
                ( ( r_trap(j)**2d0 + (zzzz(1)+vzi)**(2d0) + vri**(2d0) )**(-3d0/2d0) )&
                *(zzzz(1)+vzi)*int1_p(j) )


        ENDDO


        CALL trap(i1_lb,rrrr(1),N_trap,u_vr,int_approx2)

        temp = (1d0)*((deltaPhi*vri)/(2d0*pi))*int_approx2

        !write(*,*) 'integral 2 of node 1', temp

        vpotential1 = int_approx1 + temp


        RETURN
    END SUBROUTINE



    SUBROUTINE tester(N, N_trap, r, z, a, c, delPhi, arc_int, uvort, wvort)

        IMPLICIT NONE

        INTEGER                                      :: i, j, N, N_trap, torus_switch
        DOUBLE PRECISION                             :: pi, a, c, i1_lb, i1_hb, i2_lb, i2_hb,&
            length, delPhi
        DOUBLE PRECISION, DIMENSION(N+1,N_trap+1)     :: ss, r_sp, z_sp, dr_sp, dz_sp, dpp, dmm,&
            kktm, kktp, u, w, int_func, int1_p, int1_m,&
            int2_p, int2_m
        DOUBLE PRECISION, DIMENSION(N_trap+1,N_trap+1) :: i1m, i1p, i2m, i2p
        DOUBLE PRECISION, DIMENSION(N+1)             :: arc_int, r, z, ar, br, cr, dr, er, az,&
            bz, cz, dz, ez,&
            s, ds, uvort, wvort

        write(*,*) 's2'
        pi = 4d0*datan(1d0)
        i1_lb = 0d0
        i1_hb = pi
        i2_lb = 0d0
        i2_hb = pi
        s = 0d0
        ar = 0d0
        br = 0d0
        cr = 0d0
        az = 0d0
        bz = 0d0
        cz = 0d0
        arc_int = 0d0
        r_sp = 0d0
        z_sp = 0d0


        torus_switch = 1

        write(*,*) '2b'

        CALL iterative_arclength_calc(r, z, ar, br, cr, dr, er, az, bz, cz,&
            dz, ez, s, length, N, torus_switch)

        write(*,*) 'a'

        DO i=1,(N)
            ds(i) = s(i+1)-s(i)
        ENDDO

        write(*,*) '2c'

        DO i=1,N                           ! Loops over nodes 1 to np.
            DO j=1,(N_trap + 1)               ! Loop for trapezoidal rule between each segment.


                i1m(j,:) = 0d0
                i2m(j,:) = 0d0
                i1p(j,:) = 0d0
                i2p(j,:) = 0d0

                ss(i,j)    = s(i) + (j-1)*ds(i)/dble(N_trap)

                r_sp(i,j)  = ar(i)*(ss(i,j) - s(i))**5d0 + br(i)*(ss(i,j) - s(i))**4d0&
                    + cr(i)*(ss(i,j) - s(i))**3d0 + dr(i)*(ss(i,j) - s(i))**2d0 &
                    + er(i)*(ss(i,j) - s(i)) + r(i)

                z_sp(i,j)  = az(i)*(ss(i,j) - s(i))**5d0 + bz(i)*(ss(i,j) - s(i))**4d0&
                    + cz(i)*(ss(i,j) - s(i))**3d0 + dz(i)*(ss(i,j) - s(i))**2d0 &
                    + ez(i)*(ss(i,j) - s(i)) + z(i)

                dr_sp(i,j) = 5d0*ar(i)*(ss(i,j) - s(i))**4d0 + 4d0*br(i)*(ss(i,j) - s(i))**3d0 +&
                    3d0*cr(i)*(ss(i,j) - s(i))**2d0 + 2d0*dr(i)*(ss(i,j) - s(i)) + er(i)

                dz_sp(i,j) = 5d0*az(i)*(ss(i,j) - s(i))**4d0 + 4d0*bz(i)*(ss(i,j) - s(i))**3d0 +&
                    3d0*cz(i)*(ss(i,j) - s(i))**2d0 + 2d0*dz(i)*(ss(i,j) - s(i)) + ez(i)

                dpp(i,j)   = ( r_sp(i,j)**2d0 + a**2d0 + (z_sp(i,j) + c)**2d0 )
                dmm(i,j)   = ( r_sp(i,j)**2d0 + a**2d0 + (z_sp(i,j) - c)**2d0 )

                kktm(i,j)  = (2d0*a*r_sp(i,j) ) / dmm(i,j)
                kktp(i,j)  = (2d0*a*r_sp(i,j) ) / dpp(i,j)

                CALL int_1_2_fct( kktm(i,j),N_trap,i1m(j,:),i2m(j,:) )
                CALL int_1_2_fct( kktp(i,j),N_trap,i1p(j,:),i2p(j,:) )

                write(*,*) 'b'

                CALL trap( i1_lb,i1_hb,N_trap,i1p(j,:),int1_p(i,j) )
                CALL trap( i1_lb,i1_hb,N_trap,i1m(j,:),int1_m(i,j) )

                CALL trap( i1_lb,i1_hb,N_trap,i2p(j,:),int2_p(i,j) )
                CALL trap( i1_lb,i1_hb,N_trap,i2m(j,:),int2_m(i,j) )

                write(*,*) 'c'

                u(i,j) = (1d0)*(delPhi*a / (2d0*pi) ) * (&
                    ( dmm(i,j)**(-3d0/2d0) )*(z_sp(i,j) - c)*int1_m(i,j) - &
                    ( dpp(i,j)**(-3d0/2d0) )*(z_sp(i,j) + c)*int1_p(i,j)   )

                w(i,j) = (1d0)*(delPhi*a / (2d0*pi) ) * (&
                    ( dmm(i,j)**(-3d0/2d0) )*( a*int2_m(i,j) - r_sp(i,j)*int1_m(i,j) )&
                    - ( dpp(i,j)**(-3d0/2d0) )*( a*int2_p(i,j) - r_sp(i,j)*int1_p(i,j) )    )


                int_func(i,j) = ( u(i,j) * dr_sp(i,j) ) + ( w(i,j) * dz_sp(i,j) )

            ENDDO

            uvort(i) = u(i,1)
            wvort(i) = w(i,1)

            write(*,*) 'd'

            CALL trap( s(i), s(i+1), N_trap, int_func(i,:), arc_int(i+1) )

            write(*,*) 'e'

        ENDDO

        uvort(N+1) = u(N,N_trap+1)
        wvort(N+1) = w(N,N_trap+1)


        RETURN
    END SUBROUTINE




    SUBROUTINE arcint_calc(N, N_trap, r, z, a, c, delPhi, arc_int, uvort, wvort)


        IMPLICIT NONE

        INTEGER                                      :: i, j, N, N_trap, torus_switch
        DOUBLE PRECISION                             :: pi, a, c, i1_lb, i1_hb, i2_lb, i2_hb,&
            length, delPhi
        DOUBLE PRECISION, DIMENSION(N+1,N_trap+1)     :: ss, r_sp, z_sp, dr_sp, dz_sp, dpp, dmm,&
            kktm, kktp, u, w, int_func, int1_p, int1_m,&
            int2_p, int2_m
        DOUBLE PRECISION, DIMENSION(N_trap+1,N_trap+1) :: i1m, i1p, i2m, i2p
        DOUBLE PRECISION, DIMENSION(N+1)             :: arc_int, r, z, ar, br, cr, dr, er, az,&
            bz, cz, dz, ez,&
            s, ds, uvort, wvort


        pi = 4d0*datan(1d0)
        i1_lb = 0d0
        i1_hb = pi
        i2_lb = 0d0
        i2_hb = pi
        s = 0d0
        ar = 0d0
        br = 0d0
        cr = 0d0
        az = 0d0
        bz = 0d0
        cz = 0d0
        arc_int = 0d0
        r_sp = 0d0
        z_sp = 0d0


        torus_switch = 1


        CALL iterative_arclength_calc(r, z, ar, br, cr, dr, er, az, bz, cz,&
            dz, ez, s, length, N, torus_switch)


        DO i=1,(N)
            ds(i) = s(i+1)-s(i)
        ENDDO


        DO i=1,N                           ! Loops over nodes 1 to np.
            DO j=1,(N_trap + 1)               ! Loop for trapezoidal rule between each segment.


                i1m(j,:) = 0d0
                i2m(j,:) = 0d0
                i1p(j,:) = 0d0
                i2p(j,:) = 0d0

                ss(i,j)    = s(i) + (j-1)*ds(i)/dble(N_trap)

                r_sp(i,j)  = ar(i)*(ss(i,j) - s(i))**5d0 + br(i)*(ss(i,j) - s(i))**4d0&
                    + cr(i)*(ss(i,j) - s(i))**3d0 + dr(i)*(ss(i,j) - s(i))**2d0 &
                    + er(i)*(ss(i,j) - s(i)) + r(i)

                z_sp(i,j)  = az(i)*(ss(i,j) - s(i))**5d0 + bz(i)*(ss(i,j) - s(i))**4d0&
                    + cz(i)*(ss(i,j) - s(i))**3d0 + dz(i)*(ss(i,j) - s(i))**2d0 &
                    + ez(i)*(ss(i,j) - s(i)) + z(i)

                dr_sp(i,j) = 5d0*ar(i)*(ss(i,j) - s(i))**4d0 + 4d0*br(i)*(ss(i,j) - s(i))**3d0 +&
                    3d0*cr(i)*(ss(i,j) - s(i))**2d0 + 2d0*dr(i)*(ss(i,j) - s(i)) + er(i)

                dz_sp(i,j) = 5d0*az(i)*(ss(i,j) - s(i))**4d0 + 4d0*bz(i)*(ss(i,j) - s(i))**3d0 +&
                    3d0*cz(i)*(ss(i,j) - s(i))**2d0 + 2d0*dz(i)*(ss(i,j) - s(i)) + ez(i)

                dpp(i,j)   = ( r_sp(i,j)**2d0 + a**2d0 + (z_sp(i,j) + c)**2d0 )
                dmm(i,j)   = ( r_sp(i,j)**2d0 + a**2d0 + (z_sp(i,j) - c)**2d0 )

                kktm(i,j)  = (2d0*a*r_sp(i,j) ) / dmm(i,j)
                kktp(i,j)  = (2d0*a*r_sp(i,j) ) / dpp(i,j)

                CALL int_1_2_fct( kktm(i,j),N_trap,i1m(j,:),i2m(j,:) )
                CALL int_1_2_fct( kktp(i,j),N_trap,i1p(j,:),i2p(j,:) )


                CALL trap( i1_lb,i1_hb,N_trap,i1p(j,:),int1_p(i,j) )
                CALL trap( i1_lb,i1_hb,N_trap,i1m(j,:),int1_m(i,j) )

                CALL trap( i1_lb,i1_hb,N_trap,i2p(j,:),int2_p(i,j) )
                CALL trap( i1_lb,i1_hb,N_trap,i2m(j,:),int2_m(i,j) )


                u(i,j) = (1d0)*(delPhi*a / (2d0*pi) ) * (&
                    ( dmm(i,j)**(-3d0/2d0) )*(z_sp(i,j) - c)*int1_m(i,j) - &
                    ( dpp(i,j)**(-3d0/2d0) )*(z_sp(i,j) + c)*int1_p(i,j)   )

                w(i,j) = (1d0)*(delPhi*a / (2d0*pi) ) * (&
                    ( dmm(i,j)**(-3d0/2d0) )*( a*int2_m(i,j) - r_sp(i,j)*int1_m(i,j) )&
                    - ( dpp(i,j)**(-3d0/2d0) )*( a*int2_p(i,j) - r_sp(i,j)*int1_p(i,j) )    )


                int_func(i,j) = ( u(i,j) * dr_sp(i,j) ) + ( w(i,j) * dz_sp(i,j) )

            ENDDO

            uvort(i) = u(i,1)
            wvort(i) = w(i,1)


            CALL trap( s(i), s(i+1), N_trap, int_func(i,:), arc_int(i+1) )


        ENDDO

        uvort(N+1) = u(N,N_trap+1)
        wvort(N+1) = w(N,N_trap+1)

        RETURN

    END SUBROUTINE


    SUBROUTINE arcint_calc2(N, N_int, N_trap, r, z, a, c, delPhi, arc_int, uvort, wvort)


        IMPLICIT NONE

        INTEGER                                      :: i, j, N, N_int, N_trap, torus_switch
        DOUBLE PRECISION                             :: pi, a, c, i1_lb, i1_hb, i2_lb, i2_hb,&
            length, delPhi
        DOUBLE PRECISION, DIMENSION(N+1,6)           :: ss, r_sp, z_sp, dr_sp, dz_sp, dpp, dmm,&
            kktm, kktp, u, w, int_func, int1_p, int1_m,&
            int2_p, int2_m
        DOUBLE PRECISION, DIMENSION(6,6)             :: i1m, i1p, i2m, i2p
        DOUBLE PRECISION, DIMENSION(N+1)             :: arc_int, r, z, ar, br, cr, dr, er, az,&
            bz, cz, dz, ez,&
            s, ds, uvort, wvort
        DOUBLE PRECISION, DIMENSION(6)               :: gi, wt


        N_trap = N_trap !Unused in this routine
        N_int = N_int
        pi = 4d0*datan(1d0)
        i1_lb = 0d0
        i1_hb = pi
        i2_lb = 0d0
        i2_hb = pi
        s = 0d0
        ar = 0d0
        br = 0d0
        cr = 0d0
        az = 0d0
        bz = 0d0
        cz = 0d0
        arc_int = 0d0
        r_sp = 0d0
        z_sp = 0d0


        torus_switch = 1

        CALL iterative_arclength_calc(r, z, ar, br, cr, dr, er, az, bz, cz,&
            dz, ez, s, length, N, torus_switch)


        DO i=1,(N)
            ds(i) = s(i+1)-s(i)
        ENDDO


        gi(1)=-0.93246951420315202781
        gi(2)=-0.66120938646626451366
        gi(3)=-0.23861918608319690863     !6-gauss points
        gi(4)=0.23861918608319690863
        gi(5)=0.66120938646626451366
        gi(6)=0.93246951420315202781

        wt(1)=0.17132449237917034504
        wt(2)=0.36076157304813860757
        wt(3)=0.46791393457269104739       !6-gauss wieghts
        wt(4)=0.46791393457269104739
        wt(5)=0.36076157304813860757
        wt(6)=0.17132449237917034504


        DO i=1,N                           ! Loops over nodes 1 to np.
            DO j=1,6               ! Loop for trapezoidal rule between each segment.

                ss(i,j) = (ds(i)/2d0)*gi(j) + ( s(i+1)+s(i) )/2d0
                !ss(i,j)    = s(i) + (j-1)*ds(i)/5d0

                r_sp(i,j)  = ar(i)*(ss(i,j) - s(i))**5d0 + br(i)*(ss(i,j) - s(i))**4d0&
                    + cr(i)*(ss(i,j) - s(i))**3d0 + dr(i)*(ss(i,j) - s(i))**2d0 &
                    + er(i)*(ss(i,j) - s(i)) + r(i)

                z_sp(i,j)  = az(i)*(ss(i,j) - s(i))**5d0 + bz(i)*(ss(i,j) - s(i))**4d0&
                    + cz(i)*(ss(i,j) - s(i))**3d0 + dz(i)*(ss(i,j) - s(i))**2d0 &
                    + ez(i)*(ss(i,j) - s(i)) + z(i)

                dr_sp(i,j) = 5d0*ar(i)*(ss(i,j) - s(i))**4d0 + 4d0*br(i)*(ss(i,j) - s(i))**3d0 +&
                    3d0*cr(i)*(ss(i,j) - s(i))**2d0 + 2d0*dr(i)*(ss(i,j) - s(i)) + er(i)

                dz_sp(i,j) = 5d0*az(i)*(ss(i,j) - s(i))**4d0 + 4d0*bz(i)*(ss(i,j) - s(i))**3d0 +&
                    3d0*cz(i)*(ss(i,j) - s(i))**2d0 + 2d0*dz(i)*(ss(i,j) - s(i)) + ez(i)

                dpp(i,j)   = ( r_sp(i,j)**2d0 + a**2d0 + (z_sp(i,j) + c)**2d0 )
                dmm(i,j)   = ( r_sp(i,j)**2d0 + a**2d0 + (z_sp(i,j) - c)**2d0 )

                kktm(i,j)  = (2d0*a*r_sp(i,j) ) / dmm(i,j)
                kktp(i,j)  = (2d0*a*r_sp(i,j) ) / dpp(i,j)


                CALL int_1_2_fct2( kktm(i,j),5,i1m(j,:),i2m(j,:) )
                CALL int_1_2_fct2( kktp(i,j),5,i1p(j,:),i2p(j,:) )

                int1_m(i,j) = (pi/2d0)*sum(i1m(j,:))
                int2_m(i,j) = (pi/2d0)*sum(i2m(j,:))
                int1_p(i,j) = (pi/2d0)*sum(i1p(j,:))
                int2_p(i,j) = (pi/2d0)*sum(i2p(j,:))

                u(i,j) = (1d0)*(delPhi*a / (2d0*pi) ) * (&
                    ( dmm(i,j)**(-3d0/2d0) )*(z_sp(i,j) - c)*int1_m(i,j) - &
                    ( dpp(i,j)**(-3d0/2d0) )*(z_sp(i,j) + c)*int1_p(i,j)   )

                w(i,j) = (1d0)*(delPhi*a / (2d0*pi) ) * (&
                    ( dmm(i,j)**(-3d0/2d0) )*( a*int2_m(i,j) - r_sp(i,j)*int1_m(i,j) )&
                    - ( dpp(i,j)**(-3d0/2d0) )*( a*int2_p(i,j) - r_sp(i,j)*int1_p(i,j) )    )


                int_func(i,j) = ( ( u(i,j) * dr_sp(i,j) ) + ( w(i,j) * dz_sp(i,j) ) )*wt(j)

            ENDDO

            uvort(i) = u(i,1)
            wvort(i) = w(i,1)

            !CALL trap( s(i), s(i+1), N_int, int_func(i,:), arc_int(i+1) )

            arc_int(i+1) = (ds(i)/2d0)*sum(int_func(i,:))

        ENDDO

        uvort(N+1) = u(N,6)
        wvort(N+1) = w(N,6)

        RETURN

    END SUBROUTINE



    SUBROUTINE new_vortpot(r, z, N, a, c, deltaPhi, vrphi, uvort, wvort)

        IMPLICIT NONE
        INTEGER                                   :: i, N
        DOUBLE PRECISION                          :: pi,&
            deltaPhi, a, c
        DOUBLE PRECISION, DIMENSION(N+1)          :: r, z, f, SA, vrphi, u, v,&
            derf, uvort, wvort

        vrphi = 0d0
        !c = ( z(1) + z(N+1) )/2d0
        pi = 4d0*datan(1d0)
        f = 0d0
        u = 0d0
        v = 0d0


        DO i=1,(N+1)

            u(i) = r(i)**2d0 - a**2d0 + (-c+z(i))**2d0

            v(i) = (  &
                (a**2d0-r(i)**2d0)**2d0 + &
                ( (-c+z(i))**2d0  )*( (-c+z(i))**2d0 + 2d0*(a**2d0+r(i)**2d0) )  &
                )**(-0.5d0)

            f(i) = u(i)*v(i)

            SA(i) = 2d0*pi*( 1d0 - ( (1d0+f(i))/2d0 )**0.5d0 )

            vrphi(i) = deltaPhi*SA(i)/(4d0*pi)

            if(z(i).gt.c)then
                ! vrphi(i) = vrphi(i) - deltaPhi
                !else
                vrphi(i) = -vrphi(i)
            endif

            if((z(i).lt.c).and.(i.lt.19))then
                vrphi(i) = vrphi(i) - deltaPhi
            endif
        ENDDO

        ! Differentiating to give vortex velocity

        DO i=1,(N+1)

            derf(i) = (-1d0)*( deltaPhi/8d0 )*( ( 2d0/(1d0+f(i)) )**(0.5d0) )

            uvort(i) = 0.5d0*r(i)*derf(i)*( (v(i)-u(i)*f(i))/(v(i)**2d0) )

            wvort(i) = 0.5d0*(z(i)-c)*derf(i)*( (v(i)-2d0*(u(i)+2d0*a**2d0)*f(i))/(v(i)**2d0) )

        ENDDO

        RETURN

    END SUBROUTINE




    SUBROUTINE vortex_velocity(N,N_trap,deltaPhi,rrr,zzz,vri,vzi,u_vort,w_vort)

        IMPLICIT NONE

        INTEGER                                   :: i, N_trap, N
        DOUBLE PRECISION                          :: pi, i1_lb, i1_hb, i2_lb, i2_hb,&
            deltaPhi, vri, vzi
        DOUBLE PRECISION, DIMENSION(N+1)          :: int1_m, int1_p, int2_m, int2_p,&
            ddm, ddp, rrr, zzz, kkm, kkp,&
            u_vort, w_vort
        DOUBLE PRECISION, DIMENSION(N+1,N_trap+1) :: i1p, i1m, i2m, i2p

        pi = 4d0*datan(1d0)
        i1_lb = 0d0
        i1_hb = pi
        i2_lb = 0d0
        i2_hb = pi
        u_vort = 0d0
        w_vort = 0d0
        ddm = 0d0
        ddp = 0d0
        kkm = 0d0
        kkp = 0d0
        int1_m = 0d0
        int1_p = 0d0
        int2_m = 0d0
        int2_p = 0d0


        DO i=1,(N+1)

            ddm(i) = ( vri**2d0 + (zzz(i)-vzi)**2d0 + rrr(i)**2d0 )**(1d0/2d0)
            ddp(i) = ( vri**2d0 + (zzz(i)+vzi)**2d0 + rrr(i)**2d0 )**(1d0/2d0)

            kkm(i) = (2d0*rrr(i)*vri ) / (ddm(i)**2d0)
            kkp(i) = (2d0*rrr(i)*vri ) / (ddp(i)**2d0)

            CALL int_1_2_fct( kkm(i),N_trap,i1m(i,:),i2m(i,:) )
            CALL int_1_2_fct( kkp(i),N_trap,i1p(i,:),i2p(i,:) )

            CALL trap( i1_lb,i1_hb,N_trap,i1p(i,:),int1_p(i) )
            CALL trap( i1_lb,i1_hb,N_trap,i1m(i,:),int1_m(i) )

            CALL trap( i2_lb,i2_hb,N_trap,i2p(i,:),int2_p(i) )
            CALL trap( i2_lb,i2_hb,N_trap,i2m(i,:),int2_m(i) )

            u_vort(i) = (1d0)*( (deltaPhi*vri) / (2d0*pi) )*&
                ( (ddm(i)**(-3d0))*(zzz(i) - vzi)*int1_m(i)-&
                (ddp(i)**(-3d0))*(zzz(i) + vzi)*int1_p(i) )

            w_vort(i) = (1d0)*( (deltaPhi*vri) / (2d0*pi) )*&
                ( (ddm(i)**(-3d0))*( vri*int2_m(i)-(rrr(i)*int1_m(i)) )&
                - (ddp(i)**(-3d0))*( vri*int2_p(i)-(rrr(i)*int1_p(i)) ) )


        ENDDO



        RETURN

    END SUBROUTINE


    SUBROUTINE en_seg2(aaaphi, bbbphi, cccphi, dddphi, eeephi, ar, br, cr, dr, er, r,&
        pphiHP, s1, s2, NN_trap, En1)

        INTEGER                                :: k, NN_trap
        DOUBLE PRECISION                       :: s1, s2,&
            pphiHP, aaaphi, bbbphi, cccphi, dddphi,&
            eeephi, EN1, ar, br, cr, dr, er, r
        DOUBLE PRECISION, DIMENSION(6)         :: funct, ss, rr
        DOUBLE PRECISION, DIMENSION(6)         :: gi, w, EE1

        NN_trap = NN_trap !Unused
        EE1 = 0d0
        ss = 0d0
        ppphi = 0d0
        HHP = 0d0
        funct = 0d0
        EE1 = 0d0
        gi = 0d0
        w = 0d0
        En1 = 0d0


        gi(1)=-0.93246951420315202781
        gi(2)=-0.66120938646626451366
        gi(3)=-0.23861918608319690863     !6-gauss points
        gi(4)=0.23861918608319690863
        gi(5)=0.66120938646626451366
        gi(6)=0.93246951420315202781

        w(1)=0.17132449237917034504
        w(2)=0.36076157304813860757
        w(3)=0.46791393457269104739       !6-gauss weights
        w(4)=0.46791393457269104739
        w(5)=0.36076157304813860757
        w(6)=0.17132449237917034504

        DO k = 1,6

            ss(k)    = ((s2 - s1)/2d0)*gi(k) + (s2 + s1)/2d0 !arclength function of gauss-point

            funct(k) = aaaphi*(ss(k) - s1)**5d0 + bbbphi*(ss(k) - s1)**4d0 +&
                cccphi*(ss(k) - s1)**3d0 + dddphi*(ss(k) - s1)**2d0 +&
                eeephi*(ss(k) - s1) + pphiHP !phi spline


            rr(k) = ar*(ss(k) - s1)**5d0 + br*(ss(k) - s1)**4d0 +&
                cr*(ss(k) - s1)**3d0 + dr*(ss(k) - s1)**2d0 + er*(ss(k) - s1) + r

            EE1(k)   = w(k)*funct(k)*rr(k)

        ENDDO

        En1 = ((s2 - s1)/2 )*sum(EE1)

        RETURN

    END SUBROUTINE





    !SUBROUTINE energy1_seg(aaadphidn, bbbdphidn, cccdphidn,&
    !                       aaaphi, bbbphi, cccphi,&
    !                       pphiHP, s1, s2, NN, NN_trap, En1)

    !INTEGER                                :: k, NN, NN_trap
    !DOUBLE PRECISION                       :: s1, s2, aaadphidn, bbbdphidn, cccdphidn,&
    !                                          pphiHP, aaaphi, bbbphi, cccphi, En1
    !DOUBLE PRECISION, DIMENSION(NN_trap+1) :: funct, ss, ppphi, HHP


    !En1 = 0d0


    !DO k=1,(NN_trap+1)

    !  ss(k) = s1 + (dble(k)-1d0)*(s2-s1)/dble(NN_trap)

     ! ppphi(k) = aaaphi*(ss(k) - s1)**3 + bbbphi*(ss(k) - s1)**2 +&
     !            cccphi*(ss(k) - s1) + pphi !phi spline

     ! HHP(k)   = aaadphidn*(ss(k) - s1)**3 + bbbdphidn*(ss(k) - s1)**2 +&
     !            cccdphidn*(ss(k) - s1) + HP

     ! funct(k) = ppphi(k)*HHP(k)
    !   funct(k) = aaaphi*(ss(k) - s1)**3 + bbbphi*(ss(k) - s1)**2 +&
    !             cccphi*(ss(k) - s1) + pphiHP

    !ENDDO


    !CALL trap(s1, s2, NN_trap, funct, En1)


    !RETURN

    !END SUBROUTINE



    SUBROUTINE energy_calc(r, z, N, N_trap, ar, br, cr, dr ,er,&
        aaphp, bbphp, ccphp, ddphp, eephp,&
        deltaPhi, phi, rem, HP, phiHP, s, torus_switch, vol,&
        V0, lamb, Energy,&
        epsil, delt, E1, E2, E3, E4, wall_switch,&
        jetvel, a, c, E1_app, jet_ap)



        INTEGER                             :: N, i, torus_switch, wall_switch, N_int, NNN
        DOUBLE PRECISION                    :: pi, VOLFLOW, deltaPhi, zcenter, lamb, Energy,&
            vol, V0, epsil, E1, E2, E3, E4, E1_seg, delt,&
            jetvel, jettotal, vortderiv, a, c, rmin, zmin,&
            E1a, E1b, E1_app, jet_ap(6), r_ap(6), kktm(6),&
            kktp(6), vort_ap(6), jet_tot(6), int1_p(6),&
            int1_m(6), int2_p(6), int2_m(6), w(6), gi(6),&
            i1p(6,N_trap), i1m(6,N_trap), i2p(6,N_trap),&
            i2m(6,N_trap), dpp(6), dmm(6), i1_lb, i1_hb
        DOUBLE PRECISION, DIMENSION(N+1)   :: r, z, rem, HP, phiHP, ar, br, cr, dr, er,&
            s, temp,&
            aaphp, bbphp, ccphp, ddphp, eephp, &
            phi, ttrap

        NNN = N_trap
        jetvel = jetvel
        pi = 4d0*datan(1d0)
        i1_lb = 0d0
        i1_hb = pi


        N_int = 10
        N_tot = 10*N
        wall_switch = wall_switch !Unused in this routine
        rem = rem
        E1 = 0d0
        E2 = 0d0
        E3 = 0d0
        E4 = 0d0
        VOLFLOW = 0d0
        E1a = 0d0
        E1b = 0d0
        ttrap = 0d0
        E1_app = 0d0


        rmin = minval(r)
        temp = minloc(r)
        zmin = z( int(temp(1)) )

        if(torus_switch.eq.0)then
            DO i=1,N
                CALL en_seg2(aaphp(i), bbphp(i), ccphp(i), ddphp(i), eephp(i), ar(i), br(i),&
                    cr(i), dr(i), er(i), r(i),&
                    phiHP(i), s(i), s(i+1), N_trap, E1_seg)

                E1 = E1 + E1_seg
            ENDDO

            E1 = (pi)*E1

            DO i=1,N
                ttrap(i) = ( s(i+1) - s(i) )*( phi(i+1)*HP(i+1)*r(i+1) + phi(i)*HP(i)*r(i) )
            ENDDO

            E1_app = (pi/2d0)*sum(ttrap)

        else

            ! approximate using values at nodes and trapezoidal rule
            DO i=1,N
                ttrap(i) = ( s(i+1) - s(i) )*( phiHP(i+1)*r(i+1) + phiHP(i)*r(i) )
            ENDDO


            E1 = (pi/2d0)*sum(ttrap)


        endif

        !CALL vol_flow_rate()

        zcenter = sum(z)/N                                ! z-coordinate of bubble centroid


        if(torus_switch.eq.0)then
            E2 = 0d0                                        ! Zero for pre-toroidal
        elseif(torus_switch.eq.1)then !  Assume flow through torus is constant along 0 to r1 and equal to jetvelocity
            jettotal = 0d0
            vortderiv = 0d0
            E2 = 0d0

            ! vortderiv = (-1d0)*( deltaPhi*(a**2d0)/2d0 )*( ( (zmin-c)**2d0 + (a**2d0) )**(-1.5d0) + &
            !                                               ( (zmin+c)**2d0 + (a**2d0) )**(-1.5d0) )
            !jettotal = jetvel + vortderiv


            gi(1)=-0.93246951420315202781
            gi(2)=-0.66120938646626451366
            gi(3)=-0.23861918608319690863     !6-gauss points
            gi(4)=0.23861918608319690863
            gi(5)=0.66120938646626451366
            gi(6)=0.93246951420315202781

            w(1)=0.17132449237917034504
            w(2)=0.36076157304813860757
            w(3)=0.46791393457269104739       !6-gauss wieghts
            w(4)=0.46791393457269104739
            w(5)=0.36076157304813860757
            w(6)=0.17132449237917034504

            DO i=1,6

                r_ap(i) = (rmin/2d0)*gi(i) + rmin/2d0

                dpp(i)   = ( r_ap(i)**2d0 + a**2d0 + (zmin + c)**2d0 )
                dmm(i)   = ( r_ap(i)**2d0 + a**2d0 + (zmin - c)**2d0 )

                kktm(i)  = (2d0*a*r_ap(i) ) / dmm(i)
                kktp(i)  = (2d0*a*r_ap(i) ) / dpp(i)

                CALL int_1_2_fct( kktm(i),NNN,i1m(i,:),i2m(i,:) )
                CALL int_1_2_fct( kktp(i),NNN,i1p(i,:),i2p(i,:) )

                CALL trap( i1_lb,i1_hb,NNN,i1p(i,:),int1_p(i) )
                CALL trap( i1_lb,i1_hb,NNN,i1m(i,:),int1_m(i) )

                CALL trap( i1_lb,i1_hb,NNN,i2p(i,:),int2_p(i) )
                CALL trap( i1_lb,i1_hb,NNN,i2m(i,:),int2_m(i) )

                vort_ap(i) = (1d0)*(deltaPhi*a / (2d0*pi) ) * (&
                    ( dmm(i)**(-3d0/2d0) )*( a*int2_m(i) - r_ap(i)*int1_m(i) )&
                    - ( dpp(i)**(-3d0/2d0) )*( a*int2_p(i) - r_ap(i)*int1_p(i) )    )

                jet_tot(i) = w(i)*( jet_ap(i) + vort_ap(i) )*r_ap(i)


            ENDDO
            !jettotal = sum(jet_tot)
            jettotal = (rmin/2d0)*sum(jet_tot)
            !E2 = 0.5d0*deltaPhi*( pi**2d0 )*( rmin**4d0 )*jettotal


            E2 = deltaPhi*( pi**2d0 )*( rmin**2d0 )*jettotal


        endif




        E3 = vol*( 1d0 - (delt**2d0)*zcenter )            ! Pot. energy due to position of bub.

        E4 = ( (epsil*vol)/(lamb - 1) )*( (V0/vol)**(lamb) )  ! Pot. energy due to contents


        Energy = E1 + E2 + E3 + E4

        RETURN

    END SUBROUTINE


    SUBROUTINE kinetic_torus(pot, pot_n, pot_n2, r, s1, s2,&
        aaphi, bbphi, ccphi, ddphi, eephi,&
        ar, br, cr, dr, er, En1)

        integer                          :: k, N_trap
        double precision, dimension(11)  :: ss, HP, phi, rr, EE1
        double precision                 :: En1, s2, s1, pot, pot_n, pot_n2, r,&
            aaphi, bbphi, ccphi, ddphi, eephi,&
            ar, br, cr, dr, er


        N_trap = 10
        ! pot,pot2 = potential phi at s_i and s_i+1, pot_n pot_n2 = dphi_dn at...




        DO k=1,(11)

            ss(k) = s1 + (k-1)*( s2 - s1 )/dble(N_trap)

            HP(k) = ( (s2 - ss(k))/(s2 - s1) )*pot_n + ( (ss(k) - s1)/(s2 - s1) )*pot_n2

            phi(k) = aaphi*(ss(k) - s1)**5d0 + bbphi*(ss(k) - s1)**4d0 +&
                ccphi*(ss(k) - s1)**3d0 + ddphi*(ss(k) - s1)**2d0 +&
                eephi*(ss(k) - s1) + pot !phi spline

            rr(k) = ar*(ss(k) - s1)**5d0 + br*(ss(k) - s1)**4d0 +&
                cr*(ss(k) - s1)**3d0 + dr*(ss(k) - s1)**2d0 + er*(ss(k) - s1) + r

            EE1(k)   = HP(k)*phi(k)*rr(k)

        ENDDO

        CALL trap(s1,s2,N_trap,EE1,En1)



        RETURN
    END SUBROUTINE

    SUBROUTINE kinetic_torus2(phi, pot_n, pot_n2, r, s1, s2,&
        ar, br, cr, dr, er, En1)

        integer                          :: k, N_trap
        double precision, dimension(11)  :: ss, HP, phi, rr, EE1
        double precision                 :: En1, s2, s1, pot_n, pot_n2, r,&
            ar, br, cr, dr, er


        N_trap = 5
        ! pot,pot2 = potential phi at s_i and s_i+1, pot_n pot_n2 = dphi_dn at...




        DO k=1,(11)

            ss(k) = s1 + (k-1)*( s2 - s1 )/dble(N_trap)

            HP(k) = ( (s2 - ss(k))/(s2 - s1) )*pot_n + ( (ss(k) - s1)/(s2 - s1) )*pot_n2


            rr(k) = ar*(ss(k) - s1)**5d0 + br*(ss(k) - s1)**4d0 +&
                cr*(ss(k) - s1)**3d0 + dr*(ss(k) - s1)**2d0 + er*(ss(k) - s1) + r

            EE1(k)   = HP(k)*phi(k)*rr(k)

        ENDDO

        CALL trap(s1,s2,N_trap,EE1,En1)



        RETURN
    END SUBROUTINE

    SUBROUTINE rem_spline(rem_pot, aphir, bphir, cphir, dphir, ephir, s,&
        N_int, N, remspline, drem, d2rem, ss)


        INTEGER                    :: N, N_int, i, j
        DOUBLE PRECISION           :: rem_pot(N+1), aphir(N+1), bphir(N+1), cphir(N+1),&
            dphir(N+1), ephir(N+1),&
            s(N+1), remspline(N,N_int+1), drem(N,N_int+1),&
            d2rem(N,N_int+1), ss(N,N_int+1)


        ss = 0d0
        remspline = 0d0
        drem = 0d0
        d2rem = 0d0
        ! i loops over each node, j is a loop within each segment


        DO i = 1,(N)
            DO j = 1, (N_int+1)

                ss(i,j) = s(i) + (j-1d0)*(s(i+1)-s(i))/(dble(N_int))
                remspline(i,j) = aphir(i)*(ss(i,j) - s(i))**5d0 + bphir(i)*(ss(i,j) - s(i))**4d0 +&
                    cphir(i)*(ss(i,j) - s(i))**3d0 + dphir(i)*(ss(i,j) - s(i))**2d0 +&
                    ephir(i)*(ss(i,j) - s(i)) + rem_pot(i)
                drem(i,j)   = 5d0*aphir(i)*(ss(i,j) - s(i))**(4d0) + 4d0*bphir(i)*(ss(i,j) - s(i))**3d0 + &
                    3d0*cphir(i)*(ss(i,j) - s(i))**(2d0) + 2d0*dphir(i)*(ss(i,j) - s(i)) +&
                    ephir(i)
                d2rem(i,j)  = 20d0*aphir(i)*(ss(i,j) - s(i))**3d0 + 12d0*bphir(i)*(ss(i,j) - s(i))**2d0 +&
                    6d0*cphir(i)*(ss(i,j) - s(i)) + 2d0*dphir(i)

            ENDDO
        ENDDO


        RETURN

    END SUBROUTINE


    SUBROUTINE jetvel_calc(r,z,phi,HP,N,torus_switch,wall_switch,deltaPhi,jetvel)

        INTEGER                          :: j, N, torus_switch, wall_switch
        DOUBLE PRECISION                 :: Ur, Uz, Lr, Lz, pi, II1, III, Gimage_int1,&
            Himage_int1, IIIa, Himage_int2, phiup, philow,&
            delt, length, deltaPhi, jetvel, G1, H1, G2, H2,&
            zmin, rmin
        DOUBLE PRECISION, DIMENSION(N+1) :: aar, bbr, ccr, ddr, eer, aaz, bbz, ccz, ddz,&
            eez, phi, HP,&
            adphidn, bdphidn, cdphidn, ddphidn, edphidn,&
            aphi, bphi,&
            cphi, dphi, ephi, s, r, z, temp

        deltaPhi = deltaPhi
        rmin = minval(r)
        temp = minloc(r)
        zmin = z( int(temp(1)) )

        pi = 4d0*datan(1d0)
        Gimage_int1 = 0d0
        Gimage_int2 = 0d0
        Himage_int1 = 0d0
        Himage_int2 = 0d0


        call iterative_arclength_calc(r, z, aar, bbr, ccr, ddr, eer, aaz, bbz, ccz, ddz, eez,&
            s, length, N, torus_switch)



        call Quintic_periodic_phi_parameterised_arclength(N, adphidn, bdphidn, cdphidn,&
            ddphidn, edphidn, HP, s)


        call Quintic_periodic_phi_parameterised_arclength(N, aphi, bphi, cphi, dphi, ephi, phi, s)


        delt = min(abs(zmin/4d0),0.01d0)


        Ur = 0d0
        Uz = zmin + delt          ! Coordinates of upper and lower points where phi
        Lr = 0d0                  ! will be found.
        Lz = zmin - delt


        G1 = 0d0
        H1 = 0d0

        do 82 j = 1, N   ! loop over bubble surface for upper points


            call gaussaxis_jet(r(j), z(j), Uz, aphi(j),&
                bphi(j), cphi(j), dphi(j), ephi(j),&
                aar(j), bbr(j), ccr(j), ddr(j), eer(j), aaz(j), bbz(j), ccz(j),&
                ddz(j), eez(j),&
                adphidn(j), bdphidn(j), cdphidn(j), ddphidn(j), edphidn(j), II1,&
                III, phi(j), HP(j), IIIa, s(j+1), s(j))

            !Construct linear system.
            G1 = G1 + II1    ! Gives dphidn bit
            H1 = H1 + III    ! Gives Aij bit


            if (wall_switch.eq.1) then


                call gaussaxis_jet(r(j), z(j), Uz,&
                    aphi(j), bphi(j), cphi(j), dphi(j), ephi(j),&
                    aar(j), bbr(j), ccr(j), ddr(j), eer(j), aaz(j), bbz(j), ccz(j),&
                    ddz(j), eez(j),&
                    adphidn(j), bdphidn(j), cdphidn(j), ddphidn(j),&
                    edphidn(j), Gimage_int1,&
                    Himage_int1, phi(j), HP(j), Himage_int2, s(j+1), s(j))

                !Add image Green's functions to linear system.

                G1 = G1 + Gimage_int1
                H1 = H1 + Himage_int1


            endif

            phiup = (1/(4d0*pi))*( G1 - H1 )


82      continue

        G2 = 0d0
        H2 = 0d0
        Gimage_int1 = 0d0
        Gimage_int2 = 0d0
        Himage_int1 = 0d0
        Himage_int2 = 0d0

        do 83 j = 1, N   ! loop over bubble surface for upper points


            call gaussaxis_jet(r(j), z(j), Lz, aphi(j),&
                bphi(j), cphi(j), dphi(j), ephi(j),&
                aar(j), bbr(j), ccr(j), ddr(j), eer(j), aaz(j),&
                bbz(j), ccz(j), ddz(j), eez(j),&
                adphidn(j), bdphidn(j), cdphidn(j), ddphidn(j), edphidn(j), II1,&
                III, phi(j), HP(j), IIIa, s(j+1), s(j))

            !Construct linear system.
            G2 = G2 + II1    !Gives dphidn bit
            H2 = H2 + III    ! Gives Aij bit


            if (wall_switch.eq.1) then


                call gaussaxis_jet(r(j), z(j), Lz,&
                    aphi(j), bphi(j), cphi(j), dphi(j), ephi(j),&
                    aar(j), bbr(j), ccr(j), ddr(j), eer(j), aaz(j),&
                    bbz(j), ccz(j), ddz(j), eez(j),&
                    adphidn(j), bdphidn(j), cdphidn(j), ddphidn(j), edphidn(j), Gimage_int1,&
                    Himage_int1, phi(j), HP(j), Himage_int2, s(j+1), s(j))

                !Add image Green's functions to linear system.

                G2 = G2 + Gimage_int1
                H2 = H2 + Himage_int1


            endif

            philow = (1/(4d0*pi))*( G2 - H2)


83      continue

        ! Finally, approximate jet velocity using finite differences

        jetvel = 0d0
        !jetvel = (phiup - philow + deltaPhi)/(2*delt)

        jetvel = ( philow - phiup )/( 2*delt )


        RETURN

    END SUBROUTINE



!That's it!






