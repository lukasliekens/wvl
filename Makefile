GHDL=/tmp/ghdl/bin/ghdl
GHDLFLAGS=

EXECUTABLE=inputprocessing_fulltest
SOURCES=	txt_util.vhd			\
		file_generator.vhd		\
		file_checker.vhd		\
		crc8.vhd			\
		DFL.vhd				\
		header.vhd			\
		MEM.vhd				\
		padding.vhd			\
		scrambler.vhd			\
		SR_ctrlsync.vhd			\
		SR_data.vhd			\
		inputprocessing.vhd		\
		inputprocessing_fulltest.vhd	
TESTDATA=

SOURCES_PATH=$(addprefix src/,$(SOURCES))
OBJECTS_OBJ=$(addprefix obj/,$(SOURCES:.vhd=.o))
TESTDATA_PATH=$(addprefix testdata/,$(TESTDATA))
EXECUTABLE_PATH=$(addprefix bin/,$(EXECUTABLE))

.PHONY all: $(EXECUTABLE_PATH)

.PHONY1 test: test_noscramble test_nohandshake test_handshake

PROB_SOURCE=0.8 0.4 1
PROB_SINK=0.8 0.4 1
.PHONY2 test_handshake: bin/inputprocessing_fulltest $(TESTDATA_PATH)
	$(foreach prob_sink,$(PROB_SINK), $(foreach prob_source,$(PROB_SOURCE), ./bin/inputprocessing_fulltest -ghandshake_transaction_probability_source="$(prob_source)" -ghandshake_transaction_probability_sink="$(prob_sink)" -ginput_data_file="../testvector/inputprocessing/BeforeInputProcessing/telemic_video.txt" -gcheck_data_file="../testvector/inputprocessing/AfterScrambler/output34_short_binary.txt" -gcodeRate_in=6 -ghandshake_seed=1 && ) ) true
	$(foreach prob_sink,$(PROB_SINK), $(foreach prob_source,$(PROB_SOURCE), ./bin/inputprocessing_fulltest -ghandshake_transaction_probability_source="$(prob_source)" -ghandshake_transaction_probability_sink="$(prob_sink)" -ginput_data_file="../testvector/inputprocessing/BeforeInputProcessing/telemic_video.txt" -gcheck_data_file="../testvector/inputprocessing/AfterScrambler/output12_binary.txt" -gcodeRate_in=11 -ghandshake_seed=2 && ) ) true
	$(foreach prob_sink,$(PROB_SINK), $(foreach prob_source,$(PROB_SOURCE), ./bin/inputprocessing_fulltest -ghandshake_transaction_probability_source="$(prob_source)" -ghandshake_transaction_probability_sink="$(prob_sink)" -ginput_data_file="../testvector/inputprocessing/BeforeInputProcessing/telemic_video.txt" -gcheck_data_file="../testvector/inputprocessing/AfterScrambler/output35_binary.txt" -gcodeRate_in=14 -ghandshake_seed=3 && ) ) true
	$(foreach prob_sink,$(PROB_SINK), $(foreach prob_source,$(PROB_SOURCE), ./bin/inputprocessing_fulltest -ghandshake_transaction_probability_source="$(prob_source)" -ghandshake_transaction_probability_sink="$(prob_sink)" -ginput_data_file="../testvector/inputprocessing/BeforeInputProcessing/telemic_video.txt" -gcheck_data_file="../testvector/inputprocessing/AfterScrambler/output34_binary.txt" -gcodeRate_in=16 -ghandshake_seed=1 && ) ) true

.PHONY3 test_noscramble: bin/inputprocessing_fulltest $(TESTDATA_PATH)
	./bin/inputprocessing_fulltest -ghandshake_transaction_probability_source="1" -ghandshake_transaction_probability_sink="1" -ginput_data_file="../testvector/inputprocessing/BeforeInputProcessing/telemic_video.txt" -gcheck_data_file="../testvector/inputprocessing/AfterInputProcessing/output34_short_binary.txt" -gcodeRate_in=6 -gbypassScrambler=true
	./bin/inputprocessing_fulltest -ghandshake_transaction_probability_source="1" -ghandshake_transaction_probability_sink="1" -ginput_data_file="../testvector/inputprocessing/BeforeInputProcessing/telemic_video.txt" -gcheck_data_file="../testvector/inputprocessing/AfterInputProcessing/output12_binary.txt" -gcodeRate_in=11 -gbypassScrambler=true
	./bin/inputprocessing_fulltest -ghandshake_transaction_probability_source="1" -ghandshake_transaction_probability_sink="1" -ginput_data_file="../testvector/inputprocessing/BeforeInputProcessing/telemic_video.txt" -gcheck_data_file="../testvector/inputprocessing/AfterInputProcessing/output35_binary.txt" -gcodeRate_in=14 -gbypassScrambler=true
	./bin/inputprocessing_fulltest -ghandshake_transaction_probability_source="1" -ghandshake_transaction_probability_sink="1" -ginput_data_file="../testvector/inputprocessing/BeforeInputProcessing/telemic_video.txt" -gcheck_data_file="../testvector/inputprocessing/AfterInputProcessing/output34_binary.txt" -gcodeRate_in=16 -gbypassScrambler=true

.PHONY4 test_nohandshake: bin/inputprocessing_fulltest $(TESTDATA_PATH)
	./bin/inputprocessing_fulltest -ghandshake_transaction_probability_source="1" -ghandshake_transaction_probability_sink="1" -ginput_data_file="../testvector/inputprocessing/BeforeInputProcessing/telemic_video.txt" -gcheck_data_file="../testvector/inputprocessing/AfterScrambler/output34_short_binary.txt" -gcodeRate_in=6 -gbypassScrambler=false
	./bin/inputprocessing_fulltest -ghandshake_transaction_probability_source="1" -ghandshake_transaction_probability_sink="1" -ginput_data_file="../testvector/inputprocessing/BeforeInputProcessing/telemic_video.txt" -gcheck_data_file="../testvector/inputprocessing/AfterScrambler/output12_binary.txt" -gcodeRate_in=11 -gbypassScrambler=false
	./bin/inputprocessing_fulltest -ghandshake_transaction_probability_source="1" -ghandshake_transaction_probability_sink="1" -ginput_data_file="../testvector/inputprocessing/BeforeInputProcessing/telemic_video.txt" -gcheck_data_file="../testvector/inputprocessing/AfterScrambler/output35_binary.txt" -gcodeRate_in=14 -gbypassScrambler=false
	./bin/inputprocessing_fulltest -ghandshake_transaction_probability_source="1" -ghandshake_transaction_probability_sink="1" -ginput_data_file="../testvector/inputprocessing/BeforeInputProcessing/telemic_video.txt" -gcheck_data_file="../testvector/inputprocessing/AfterScrambler/output34_binary.txt" -gcodeRate_in=16 -gbypassScrambler=false


$(EXECUTABLE_PATH): $(OBJECTS_OBJ)
	cd obj; $(GHDL) -e $(GHDLFLAGS) $(notdir $@); cp $(notdir $@) ../bin/; cd ..


obj/%.o: src/%.vhd $(SOURCES_PATH)
	cd obj; $(GHDL) -a $(CFLAGS) ../$<; cd ..

clean:
	rm -f obj/* bin/* $(TESTDATA_PATH)


