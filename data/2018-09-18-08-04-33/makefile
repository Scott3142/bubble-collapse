FC = gfortran
FFLAGS = -ffixed-line-length-none -O3 #-fimplicit-none

main:	pressure_GAUSSIAN.f90
	$(FC) $(FFLAGS) pressure_GAUSSIAN.f90 -o mainex -llapack -lblas

clean:
	rm *.dat mainex
