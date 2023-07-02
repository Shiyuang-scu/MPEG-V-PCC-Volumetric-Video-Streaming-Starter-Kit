package main

import (
	"encoding/xml"
	"fmt"
	"os"
)

const (
	baseUrl         = "http://localhost:3000/"
	dataset         = "longdress"
	nadps           = 1
	startNumber     = "1051"
	totalDuration   = "PT10S"
	segmentDuration = "30" // relative to timescale
	timescale       = "30" // ticks per second
	// filenameFormat  = "longdress_vox10_$Number$"
	filenameFormat = "S26C2AIR0$RepresentationID$_F30_$Number$"
)

// longdress
var bandwidths = [...][]int{
	{101 << 10, 41 << 10, 89 << 10, 97 << 10, 33 << 10, 98 << 10},    // R-1
	{133 << 10, 45 << 10, 122 << 10, 128 << 10, 37 << 10, 135 << 10}, // R0
	{182 << 10, 45 << 10, 179 << 10, 179 << 10, 39 << 10, 192 << 10}, // R1
}
var orientations = [...][]string{
	{"0", "1", "0", "1", "1", "0"}, // front
	{"1", "1", "0", "0", "1", "1"}, // right
	{"2", "1", "1", "1", "1", "0"}, // back
	{"3", "1", "0", "0", "1", "1"}, // left
	{"4", "1", "1", "1", "0", "1"}, // top
	{"5", "0", "0", "1", "0", "1"}, // bottom
}

type SegmentTemplate struct {
	Media       string `xml:"media,attr"`
	Duration    string `xml:"duration,attr"`
	Timescale   string `xml:"timescale,attr,omitempty"`
	StartNumber string `xml:"startNumber,attr"`
}

type Representation struct {
	Id              int             `xml:"id,attr"`
	BaseURL         string          `xml:",omitempty"`
	SegmentTemplate SegmentTemplate `xml:,omitempty"`
	Density         int             `xml:"density,attr,omitempty"`
	Width           int             `xml:"width,attr,omitempty"`
	Height          int             `xml:"height,attr,omitempty"`
	Bandwidth       int             `xml:"bandwidth,attr"`
}

type AdaptationSet struct {
	Id                   int              `xml:"id,attr"`
	SupplementalProperty []DescriptorType `xml:"SupplementalProperty"`
	Representations      []Representation `xml:"Representation"`
	ViewId               int              `xml:"viewId,attr"`
	SrcObjectId          int              `xml:"srcObjectId,attr"`
}

type DescriptorType struct {
	SchemeIdUri string `xml:"schemeIdUri,attr"`
	Value       string `xml:"value,attr,omitempty"`
	Id          string `xml:"id,attr,omitempty"`
}

type Period struct {
	Id             int             `xml:"id,attr"`
	Duration       string          `xml:"duration,attr"`
	AdaptationSets []AdaptationSet `xml:"AdaptationSet"`
}

type MPD struct {
	Format  string `xml:"format,attr"`
	Type    string `xml:"type,attr"`
	BaseURL string
	Periods []Period `xml:"Period"`
}

func main() {
	v := &MPD{
		Format:  "pointcloud/pcd",
		Type:    "static",
		BaseURL: baseUrl,
	}

	p := Period{
		Id:       1,
		Duration: totalDuration,
	}

	var adps []AdaptationSet
	i := 0
	for n := 0; i < nadps; i++ {
		for viewId := 0; viewId < 6; viewId++ {
			reps := make([]Representation, len(bandwidths))
			for j := 0; j < len(bandwidths); j++ {
				reps[j] = Representation{
					Id:        j + 1,
					Bandwidth: bandwidths[j][viewId],
					SegmentTemplate: SegmentTemplate{
						Media:       fmt.Sprintf("%s/%s_%d.bin", dataset, filenameFormat, viewId),
						Duration:    segmentDuration,
						Timescale:   timescale,
						StartNumber: startNumber,
					},
				}
			}

			adps = append(adps, AdaptationSet{
				Id:              i,
				ViewId:          viewId,
				SrcObjectId:     n,
				Representations: reps,
				// SupplementalProperty: []DescriptorType{{
				// 	SchemeIdUri: "urn:mpeg:dash:srd:2014",
				// 	Value:       fmt.Sprintf("%d, %d", n, k),
				// }},
			})
			i += 1
		}
	}

	p.AdaptationSets = adps
	v.Periods = append(v.Periods, p)

	output, err := xml.MarshalIndent(v, "", "    ")
	if err != nil {
		fmt.Printf("error: %v\n", err)
	}
	os.Stdout.Write([]byte(xml.Header))
	os.Stdout.Write(output)
}
