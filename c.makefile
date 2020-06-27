EXECUTABLE								:= $(shell basename $(shell pwd))
LIB_LIB_PATH							:= lib
LIB_INC_PATH							:= inc
SRC_PATH			    				:= src
TEST_SRC_PATH             := test
DOC_PATH                  := doc
BUILD_ROOT								:= build
TEST_BUILD_ROOT           := $(TEST_SRC_PATH)/$(BUILD_ROOT)
SOURCE_FILES							:= $(notdir $(shell find $(SRC_PATH) -type f -iname '*.c'))
VPATH                     := $(shell find $(SRC_PATH) -type d)

COMPILER									:= gcc
COMPILER_OPTIONS					:= -Wall -Wextra -MD
_INC_PATHS								:= $(shell find $(LIB_LIB_PATH) -type d -iname 'inc') $(LIB_INC_PATH)
_LIB_PATHS								:=
_LIB_NAMES								:= m criterion
INC_PATHS                 := $(_INC_PATHS:%=-I %)
LIB_PATHS                 := $(_LIB_PATHS:%=-L %)
LIB_LINKER_FLAGS          := $(_LIB_NAMES:%=-l %)

_DEBUG_INC_PATHS          :=
_DEBUG_LIB_PATHS          :=
_DEBUG_LIB_NAMES          :=
DEBUG_INC_PATHS						:= $(INC_PATHS) $(_DEBUG_INC_PATHS:%=-I %)
DEBUG_LIB_PATHS						:= $(LIB_PATHS) $(DEBUG_LIB_PATHS:%=-L %)
DEBUG_LIB_LINKER_FLAGS    := $(LIB_LINKER_FLAGS) $(_DEBUG_LIB_NAMES:%=-l %)
DEBUG_BUILD_ROOT					:= $(BUILD_ROOT)/debug
DEBUG_TEST_BUILD_ROOT     := $(TEST_BUILD_ROOT)/debug
DEBUG_COMPILER_OPTIONS		:= $(COMPILER_OPTIONS) -g3 -Og -ggdb3 -pg -coverage -D DEBUG_BUILD
DEBUG_OBJECT_FILES				:= $(SOURCE_FILES:%.c=$(DEBUG_BUILD_ROOT)/%.o)
DEBUG_DEP_FILES           := $(SOURCE_FILES:%.c=$(DEBUG_BUILD_ROOT)/%.d)
DEBUG_EXECUTABLE          := $(DEBUG_BUILD_ROOT)/$(EXECUTABLE)_dbg
DEBUG_COMPILER_LINE       := $(DEBUG_COMPILER_OPTIONS) $(DEBUG_INC_PATHS) $(DEBUG_LIB_PATHS) $(DEBUG_LIB_LINKER_FLAGS)

_RELEASE_INC_PATHS        :=
_RELEASE_LIB_PATHS        :=
_RELEASE_LIB_NAMES        :=
RELEASE_INC_PATHS					:= $(INC_PATHS) $(_RELEASE_INC_PATHS:%=-I %)
RELEASE_LIB_PATHS					:= $(LIB_PATHS) $(RELEASE_LIB_PATHS:%=-L %)
RELEASE_LIB_LINKER_FLAGS  := $(LIB_LINKER_FLAGS) $(_RELEASE_LIB_NAMES:%=-l %)
RELEASE_BUILD_ROOT				:= $(BUILD_ROOT)/release
RELEASE_TEST_BUILD_ROOT   := $(TEST_BUILD_ROOT)/release
RELEASE_COMPILER_OPTIONS	:= $(COMPILER_OPTIONS) -g0 -O3 -D RELEASE_BUILD
RELEASE_OBJECT_FILES			:= $(SOURCE_FILES:%.c=$(RELEASE_BUILD_ROOT)/%.o)
RELEASE_DEP_FILES         := $(SOURCE_FILES:%.c=$(RELEASE_BUILD_ROOT)/%.d)
RELEASE_EXECUTABLE        := $(RELEASE_BUILD_ROOT)/$(EXECUTABLE)_dbg
RELEASE_COMPILER_LINE     := $(RELEASE_COMPILER_OPTIONS) $(RELEASE_INC_PATHS) $(RELEASE_LIB_PATHS) $(RELEASE_LIB_LINKER_FLAGS)

TEST_FILES                := $(notdir $(shell find $(TEST_SRC_PATH) -type f -iname '*.c'))


define compile
	$(COMPILER) $1 -o $2 $3
endef


define compile_object
	@$(info $(shell date +%s.%N) compiling $3  ->  $2)
	@$(call compile, $1 -c, $2, $3)
	@$(info $(shell date +%s.%N) compiled  $3  ->  $2)
endef


define compile_binary
	@$(info $(shell date +%s.%N) compiling $2)
	@$(call compile, $1, $2, $3)
	@$(info $(shell date +%s.%N) compiled  $2)
endef


$(DEBUG_BUILD_ROOT)/%.o: %.c $(DEBUG_BUILD_ROOT)/%.d
$(DEBUG_BUILD_ROOT)/%.o: %.c makefile
	$(call compile_object, $(DEBUG_COMPILER_LINE), $@, $<)


$(DEBUG_EXECUTABLE): $(DEBUG_OBJECT_FILES) tags
	$(call compile_binary, $(DEBUG_COMPILER_LINE), $@, $(DEBUG_OBJECT_FILES))


$(RELEASE_BUILD_ROOT)/%.o: %.c $(RELEASE_BUILD_ROOT)/%.d
$(RELEASE_BUILD_ROOT)/%.o: %.c makefile
	$(call compile_object, $(RELEASE_COMPILER_LINE), $@, $<)


$(RELEASE_EXECUTABLE): $(RELEASE_OBJECT_FILES) tags
	$(call compile_binary, $(RELEASE_COMPILER_LINE), $@, $(RELEASE_OBJECT_FILES))
	@strip $(RELEASE_EXECUTABLE)


clean:
	rm -rf $(DEBUG_BUILD_ROOT)/* $(RELEASE_BUILD_ROOT)/* $(DEBUG_TEST_BUILD_ROOT)/* $(RELEASE_TEST_BUILD_ROOT)/*


all: debug
debug: $(DEBUG_EXECUTABLE)
release: $(RELEASE_EXECUTABLE)


tags:
	@ctags -R -h .h $(SRC_PATH)


docs:
	@doxygen Doxyfile


debug_tests: $(DEBUG_OBJECT_FILES)
release_tests: $(RELEASE_OBJECT_FILES) $(TEST_FILES)
tests: debug_tests
	for f in $(TEST_SRC_PATH)/*; do echo $f; done


$(DEBUG_DEP_FILES):
$(RELEASE_DEP_FILES):
include $(wildcard $(DEBUG_DEP_FILES))
include $(wildcard $(RELEASE_DEP_FILES))

