

VHDFILES=$(shell ls -v *.vhd)
#VHDFILES=$(sort $(wildcard *.vhd))
VHDLC=ghdl
VHDLCFLAGS=-a


all:
	@for f in $(VHDFILES); do echo $$f; $(VHDLC) $(VHDLCFLAGS) $$f; done

clean:
	@rm -rf  *.o *~ *.cf

testando:
	echo $(XX)
