all : mini-rv32ima/mini-rv32ima/mini-rv32ima

mini-rv32ima :
	git clone https://github.com/cnlohr/mini-rv32ima

mini-rv32ima/mini-rv32ima/mini-rv32ima : mini-rv32ima
	make -C mini-rv32ima/mini-rv32ima mini-rv32ima

clean :
