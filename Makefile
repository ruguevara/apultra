CC=clang
CFLAGS=-O3 -g -fomit-frame-pointer -Isrc/libdivsufsort/include -Isrc
OBJDIR=obj
LDFLAGS=

$(OBJDIR)/%.o: src/../%.c
	@mkdir -p '$(@D)'
	$(CC) $(CFLAGS) -c $< -o $@

APP := apultra

OBJS += $(OBJDIR)/src/apultra.o
OBJS += $(OBJDIR)/src/expand.o
OBJS += $(OBJDIR)/src/matchfinder.o
OBJS += $(OBJDIR)/src/shrink.o
OBJS += $(OBJDIR)/src/libdivsufsort/lib/divsufsort.o
OBJS += $(OBJDIR)/src/libdivsufsort/lib/divsufsort_utils.o
OBJS += $(OBJDIR)/src/libdivsufsort/lib/sssort.o
OBJS += $(OBJDIR)/src/libdivsufsort/lib/trsort.o

all: $(APP)

src/apultra.c:	src/matchfinder.h src/format.h
src/shrink.c:	src/shrink.h src/format.h src/matchfinder.h

$(APP): $(OBJS)
	$(CC) $^ $(LDFLAGS) -o $(APP)

clean:
	@rm -rf $(APP) $(OBJDIR)
