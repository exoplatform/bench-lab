package main

import (
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strings"
	"text/template"
)

func main() {

	if len(os.Args) != 3 {
		fmt.Println("Usage : template <template path> <output file>")
		os.Exit(-1)
	}

	templatePath := os.Args[1]
	target := os.Args[2]

	envMap, _ := envToMap()
	if (len(os.Getenv("DEBUG")) > 0) {
		fmt.Println(envMap)
	}

	t := template.Must(template.ParseFiles(templatePath))

	// Create the directory tree before creating the file
	p := filepath.Dir(target)
	os.MkdirAll(p, 0775)

	f, err := os.Create(target)
	if err != nil {
		log.Fatal("Error creating file ", target, " : ", err)
	}

	fmt.Print("Populate template", templatePath, " into ", target, "...")

	err = t.Execute(f, envMap)
	if err != nil {
		log.Fatal("executing template:", err)
	}
	fmt.Println("done")

}

func envToMap() (map[string]string, error) {
	envMap := make(map[string]string)
	var err error

	for _, v := range os.Environ() {
		split_v := strings.Split(v, "=")
		envMap[split_v[0]] = split_v[1]
	}

	return envMap, err
}
