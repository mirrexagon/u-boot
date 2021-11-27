# SPDX-License-Identifier: GPL-2.0+
# Copyright (c) 2016 Google, Inc
# Written by Simon Glass <sjg@chromium.org>
#
# Entry-type module for producing an image using mkimage
#

from collections import OrderedDict

from binman.entry import Entry
from dtoc import fdt_util
from patman import tools

class Entry_mkimage(Entry):
    """Binary produced by mkimage

    Properties / Entry arguments:
        - datafile: Filename for -d argument
        - args: Other arguments to pass

    The data passed to mkimage is collected from subnodes of the mkimage node,
    e.g.::

        mkimage {
            args = "-n test -T imximage";

            u-boot-spl {
            };
        };

    This calls mkimage to create an imximage with u-boot-spl.bin as the input
    file. The output from mkimage then becomes part of the image produced by
    binman.

    To use CONFIG options in the arguments, use a string list instead, as in
    this example which also produces four arguments::

        mkimage {
            args = "-n", CONFIG_SYS_SOC, "-T imximage";

            u-boot-spl {
            };
        };

    """
    def __init__(self, section, etype, node):
        super().__init__(section, etype, node)
        self._args = fdt_util.GetArgs(self._node, 'args')
        self._mkimage_entries = OrderedDict()
        self.align_default = None
        self.ReadEntries()

    def ObtainContents(self):
        # For multiple inputs to mkimage, we want to separate them by colons.
        # This is needed for eg. the rkspi format, which treats the first data
        # file as the "init" and the second as "boot" and sets the image header
        # accordingly, then makes the image so that only the first 2 KiB of each
        # 4KiB block is used.

        data_filenames = []
        for entry in self._mkimage_entries.values():
            # First get the input data and put it in a file. If any entry is not
            # available, try later.
            if not entry.ObtainContents():
                return False

            input_fname = tools.get_output_filename('mkimage-in.%s' % entry.GetUniqueName())
            data_filenames.append(input_fname)
            tools.write_file(input_fname, entry.GetData())

        output_fname = tools.get_output_filename('mkimage-out.%s' % self.GetUniqueName())
        if self.mkimage.run_cmd('-d', ":".join(data_filenames), *self._args, output_fname):
            self.SetContents(tools.read_file(output_fname))
            return True
        else:
            self.record_missing_bintool(self.mkimage)
            return False

    def ReadEntries(self):
        """Read the subnodes to find out what should go in this image"""
        for node in self._node.subnodes:
            entry = Entry.Create(self, node)
            entry.ReadNode()
            self._mkimage_entries[entry.name] = entry

    def SetAllowMissing(self, allow_missing):
        """Set whether a section allows missing external blobs

        Args:
            allow_missing: True if allowed, False if not allowed
        """
        self.allow_missing = allow_missing
        for entry in self._mkimage_entries.values():
            entry.SetAllowMissing(allow_missing)

    def SetAllowFakeBlob(self, allow_fake):
        """Set whether the sub nodes allows to create a fake blob

        Args:
            allow_fake: True if allowed, False if not allowed
        """
        for entry in self._mkimage_entries.values():
            entry.SetAllowFakeBlob(allow_fake)

    def CheckFakedBlobs(self, faked_blobs_list):
        """Check if any entries in this section have faked external blobs

        If there are faked blobs, the entries are added to the list

        Args:
            faked_blobs_list: List of Entry objects to be added to
        """
        for entry in self._mkimage_entries.values():
            entry.CheckFakedBlobs(faked_blobs_list)

    def AddBintools(self, btools):
        self.mkimage = self.AddBintool(btools, 'mkimage')
