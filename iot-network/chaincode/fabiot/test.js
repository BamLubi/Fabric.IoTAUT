class ca {
    

    main() {
        function MakeSensor() {
            this.timestamp = new Date();
            this.data = 'data';
            this.unit = 'unit';
            this.setData = function(){
                this.data = "dadadada";
            }
        }
        const t = new MakeSensor();
        console.log(t);
        console.log(JSON.stringify(t))
        console.log(Buffer.from(JSON.stringify(t)))
        // const to = Buffer.from(JSON.stringify(t));
        // const sensor = JSON.parse(to.toString());
        // sensor._proto_ = Object.setPrototypeOf(sensor, MakeSensor.prototype)
        // console.log(sensor);
        // MakeSensor.setData.call(sensor);
        // sensor.setData();
        // console.log(sensor);
        // const car = new makecar("asd", 123);
        // console.log(car)
        // console.log(typeof car)
        // console.log(JSON.stringify(car))
        // console.log(Buffer.from(JSON.stringify(car)))
    }
}

// a = new ca();
// a.main();

// var url = 'org1-sen1';
// var reg = /org[0-9]+-sen[0-9]+/;
// console.log(reg.test(url));

let num = [{
    name: 'org1',
    id: ''
},{
    name: 'org2',
    id: ''
}];
let i = num.filter((p) => {
    return p.name == "org3";
});
console.log(i.length==0)
// console.log(num)