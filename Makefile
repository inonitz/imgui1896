COMPILER_BASE_FOLDER = "$(shell printenv MINGW_W64_COMPILER_BASE)"
PROJECT_FOLDER_BASE  = $(shell pwd)
PROJECT_FOLDER       = "$(shell cygpath -m $(PROJECT_FOLDER_BASE))"


PROJNAME = libimgui
TARGET   = $(PROJNAME).a
LINKER   = $(COMPILER_BASE_FOLDER)/bin/x86_64-w64-mingw32-ld
CPPC  	 = $(COMPILER_BASE_FOLDER)/bin/x86_64-w64-mingw32-g++
CC  	 = $(COMPILER_BASE_FOLDER)/bin/x86_64-w64-mingw32-gcc
ASMC 	 = $(COMPILER_BASE_FOLDER)/bin/x86_64-w64-mingw32-as
ARCHIVE  = $(COMPILER_BASE_FOLDER)/bin/x86_64-w64-mingw32-ar

ASMC 	 = as
ASMFLAGS = -O0
CXXFLAGS =  -c \
			-pedantic \
			-Werror \
			-Wall \
			-Wextra \
			-march=native \
			-mtune=native \


CVERSION   = c11
CXXVERSION = c++17


LIB_FILES     = -lglfw3
LIB_INC_PATHS = -I$(COMPILER_BASE_FOLDER)/../lib/GLFW/include
LIB_PATHS     = -L$(COMPILER_BASE_FOLDER)/../lib/GLFW/lib


LDFLAGS = \
		$(LIB_FILES) \
		-dl \
		-lopengl32 \
		-lm \
		-lunwind \
		-lc++ \
		-lpthread \
		-lopengl32 \
		-static-libgcc \
 		-static-libstdc++ \
		
ARFLAGS = \
	rcs \


#		-msse4.1 \
#		-msse4.2 \
#		-mavx \
#		-mavx2 \
# 		-v \
#		-lXinerama \
#		-lXcursor \
#		-lrt \
#		-ldl \
#		-lXi \
#		-lX11 \
# 		-lXxf86vm \
#		-lxcb \
#		-lXau \
#		-lXdmcp \
#		-lXrandr \




BUILDDIR_BASE 	   :=build
APPEND_RELEASE_DIR :=release
APPEND_DEBUG_DIR   :=debug
BUILDDIR 		   :=$(BUILDDIR_BASE)/

ifndef DEBUG
$(error DEBUG variable isn't defined. Can't proceed with build process)
else
$(info [DEBUG='$(DEBUG)'] DEBUG    Variable defined		   )
$(info [DEBUG='$(DEBUG)'] BUILDDIR Variable ["$(BUILDDIR)"])
endif

ifeq ('$(DEBUG)' , '1')
	BUILDDIR:=$(BUILDDIR)$(APPEND_DEBUG_DIR)
else
	BUILDDIR:=$(BUILDDIR)$(APPEND_RELEASE_DIR)
endif
$(info [DEBUG='$(DEBUG)'] BUILDDIR Variable ["$(BUILDDIR)"] )

SRCDIR    := src
OBJDIR    := $(BUILDDIR)/obj
OUTPUTDIR := $(BUILDDIR)/bin



rwildcard=$(foreach d,$(wildcard $(1:=/*)),$(call rwildcard,$d,$2) $(filter $(subst *,%,$2),$d))

CSRC    = $(call rwildcard,$(SRCDIR),*.c)
CPPSRC += $(call rwildcard,$(SRCDIR),*.cpp)
ASMSRC  = $(call rwildcard,$(SRCDIR),*.asm)
OBJS  = $(patsubst $(SRCDIR)/%.asm,$(OBJDIR)/%_asm.o,$(ASMSRC))
OBJS += $(patsubst $(SRCDIR)/%.c,$(OBJDIR)/%_c.o,$(CSRC))
OBJS += $(patsubst $(SRCDIR)/%.cpp,$(OBJDIR)/%_cpp.o,$(CPPSRC))


# Compile All C, C++, ASM Files that are part of the source directory
$(OBJDIR)/%_asm.o: $(SRCDIR)/%.asm
	@ echo compiling ASM File $^ ...
	@ mkdir -p $(@D)
	$(ASMC) $(ASMFLAGS) $^ -o $@


$(OBJDIR)/%_c.o: $(SRCDIR)/%.c
	@ echo compiling C File $^ ...
	@ mkdir -p $(@D)
	$(CC) -std=$(CVERSION) $(CXXFLAGS) $(LIB_INC_PATHS) $^ -o $@ 


$(OBJDIR)/%_cpp.o: $(SRCDIR)/%.cpp
	@ echo compiling CPP File $^ ...
	@ mkdir -p $(@D)
	$(CPPC) -std=$(CXXVERSION) $(CXXFLAGS) $(LIB_INC_PATHS) $^ -o $@




archive_lib:
	@ echo Creating Static Library ...
	$(ARCHIVE) $(ARFLAGS) $(OUTPUTDIR)/$(TARGET) $(OBJS)


bld: $(OBJS) archive_lib


rel_internal: CXXFLAGS += -O3 -ffast-math
rel_internal: bld

debug_internal: CXXFLAGS += -g -Os -D_DEBUG 
debug_internal: bld


# Don't Forget to Pipe the Output to a text file! (==> make debug_compile &> debug_out.txt)
debug_compile: CXXFLAGS += --verbose -pipe
debug_compile: rel_internal


clean_internal:
	@ echo -n "Deleting Compiled Files ... "  
	-@ rm -r $(OBJDIR)/* > /dev/null || true
	@ echo "Done! "


cleanbin_internal:
	@ echo -n Deleting Project Executable ...
	-@ rm -r $(OUTPUTDIR)/$(TARGET) > /dev/null || true
	@ echo "Done! "


run:
	@ echo Running Compiled Executable ...
	./$(OUTPUTDIR)/$(TARGET)

info:
	@ echo -e "File List: $(ASMSRC) $(CSRC) $(CPPSRC)\nObject List: $(OBJS)\n"



setup:
	mkdir -p assets
	mkdir -p src
	mkdir -p build
	mkdir -p build/debug
	mkdir -p build/debug/bin
	mkdir -p build/debug/obj
	mkdir -p build/release
	mkdir -p build/release/bin
	mkdir -p build/release/obj


.PHONY: info run cleanall cleanbin



# Release Build: 
# A> export DEBUG=0 && make -j "Your CPU Core Count * 1.5" rel_internal
# B> export DEBUG=0 && make rel_internal

# Debug Build: 
# A> export DEBUG=1 && make -j "Your CPU Core Count * 1.5" debug_internal
# B> export DEBUG=1 && make debug_internal


# if directory from recipe 'setup' is missing, call 'make setup'
# To Clean The Build Directory:
# [release] export DEBUG=0 && make clean_internal cleanbin_internal
# [ debug ] export DEBUG=1 && make clean_internal cleanbin_internal